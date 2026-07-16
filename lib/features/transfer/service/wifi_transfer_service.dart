import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/song_model.dart';

/// WiFi LAN transfer service.
///
/// **Sender flow**:
///   1. [startServer] → spins up an HTTP server, returns [WifiServerInfo]
///   2. BLoC generates a QR code from [WifiServerInfo.ip] + [WifiServerInfo.port]
///   3. Receiver scans QR → calls [downloadSongs]
///
/// **Receiver flow**:
///   1. Scan QR code → get ip + port
///   2. [downloadSongs] → GET /manifest → iterate songs → GET /song/{index}
///
/// All songs are streamed via chunked HTTP to avoid loading entire files into
/// memory. Progress is reported per chunk.
class WifiTransferService {
  static const _tag = 'WifiTransferService';
  static const int _defaultPort = 7734;

  // ── State ─────────────────────────────────────────────────────────────────
  HttpServer? _server;
  List<SongModel> _songs = [];
  bool _isActive = false;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  void Function(int index, double progress)? onProgress;
  void Function(int index)? onSongCompleted;
  void Function(int index, String reason)? onSongFailed;
  void Function()? onSessionCompleted;
  void Function(String message)? onError;

  // ── Sender side ───────────────────────────────────────────────────────────

  /// Start HTTP server and return connection info for QR generation.
  Future<WifiServerInfo> startServer(List<SongModel> songs) async {
    _songs = songs;
    _isActive = true;

    final ip = await _getLocalIp();
    final port = _defaultPort;

    final router = Router()
      ..get('/manifest', _handleManifest)
      ..get('/song/<index>', _handleSong);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    AppLogger.info('WiFi server started at $ip:$port', tag: _tag);

    return WifiServerInfo(ip: ip, port: port);
  }

  Response _handleManifest(Request request) {
    final manifest = _songs.asMap().entries.map((e) {
      final song = e.value;
      return {
        'index': e.key,
        'title': song.title,
        'artist': song.artist,
        'filename': song.data.split('/').last,
        'size': song.size,
        'duration': song.duration,
      };
    }).toList();

    return Response.ok(
      jsonEncode({'songs': manifest, 'count': _songs.length}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _handleSong(Request request, String index) {
    final idx = int.tryParse(index);
    if (idx == null || idx < 0 || idx >= _songs.length) {
      return Response.notFound('Song not found');
    }

    final song = _songs[idx];
    final file = File(song.data);

    if (!file.existsSync()) {
      return Response.notFound('File not found on disk');
    }

    final length = file.lengthSync();
    final filename = Uri.encodeComponent(song.data.split('/').last);

    return Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': 'audio/mpeg',
        'Content-Length': length.toString(),
        'Content-Disposition': 'attachment; filename="$filename"',
        'X-Song-Title': Uri.encodeComponent(song.title),
        'X-Song-Artist': Uri.encodeComponent(song.artist),
      },
    );
  }

  // ── Receiver side ─────────────────────────────────────────────────────────

  /// Download all songs from the sender's HTTP server.
  Future<void> downloadSongs({required String ip, required int port}) async {
    _isActive = true;
    final base = 'http://$ip:$port';

    try {
      // 1. Fetch manifest
      final manifestRes = await http.get(Uri.parse('$base/manifest'));
      if (manifestRes.statusCode != 200) {
        throw Exception('Failed to fetch manifest: ${manifestRes.statusCode}');
      }

      final manifestJson = jsonDecode(manifestRes.body) as Map<String, dynamic>;
      final songs =
          (manifestJson['songs'] as List).cast<Map<String, dynamic>>();

      AppLogger.info('Manifest: ${songs.length} songs to receive', tag: _tag);

      final saveDir = await _getDownloadDir();

      // 2. Download each song
      for (int i = 0; i < songs.length; i++) {
        if (!_isActive) break;

        final meta = songs[i];
        final filename = meta['filename'] as String;
        final expectedSize = meta['size'] as int;
        final destFile = File('${saveDir.path}/$filename');

        try {
          await _downloadFile(
            url: '$base/song/$i',
            dest: destFile,
            expectedSize: expectedSize,
            songIndex: i,
          );
          onSongCompleted?.call(i);
        } catch (e) {
          AppLogger.error(
            'downloadSongs index $i',
            tag: _tag,
            error: e,
          );
          onSongFailed?.call(i, e.toString());
        }
      }

      onSessionCompleted?.call();
    } catch (e, st) {
      AppLogger.error('downloadSongs', tag: _tag, error: e, stackTrace: st);
      onError?.call(e.toString());
      rethrow;
    }
  }

  Future<void> _downloadFile({
    required String url,
    required File dest,
    required int expectedSize,
    required int songIndex,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final sink = dest.openWrite();
    int received = 0;

    await for (final chunk in response.stream) {
      if (!_isActive) {
        await sink.close();
        throw Exception('Download cancelled');
      }
      sink.add(chunk);
      received += chunk.length;
      if (expectedSize > 0) {
        onProgress?.call(songIndex, received / expectedSize);
      }
    }

    await sink.close();
    AppLogger.debug('Downloaded: ${dest.path} ($received bytes)', tag: _tag);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip != null && ip.isNotEmpty) return ip;
    } catch (_) {}

    // Fallback: iterate interfaces
    for (final interface in await NetworkInterface.list()) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<Directory> _getDownloadDir() async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/MusicPlayerTransfer');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _isActive = false;
    try {
      await _server?.close(force: true);
      _server = null;
    } catch (e) {
      AppLogger.warning('WifiTransferService dispose: $e', tag: _tag);
    }
    _songs = [];
  }
}

// ── Value objects ─────────────────────────────────────────────────────────────

class WifiServerInfo {
  const WifiServerInfo({required this.ip, required this.port});
  final String ip;
  final int port;
}
