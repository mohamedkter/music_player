import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/song_model.dart';

/// Wraps `nearby_connections` for song file transfer via
/// Bluetooth / WiFi Direct (no internet required).
///
/// Architecture:
///  - Sender side: advertises → accepts connection → sends files
///  - Receiver side: discovers → requests connection → receives files
///
/// All callbacks are plain function pointers so the [TransferBloc]
/// can wire them without coupling to streams.
class NearbyTransferService {
  static const _tag = 'NearbyTransferService';
  static const _serviceId = 'com.music_player.transfer';
  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  // ── State ─────────────────────────────────────────────────────────────────
  List<SongModel> _songs = [];
  bool _isActive = false;

  /// Tracks which [payloadId] maps to which song [index] and total bytes.
  final Map<int, _IncomingFile> _incoming = {};

  // ── Callbacks set by TransferBloc ─────────────────────────────────────────
  void Function(String id, String name)? onEndpointFound;
  void Function(String id)? onEndpointLost;
  void Function(String id, String name)? onConnectionRequested;
  void Function(String id, bool success)? onConnectionResult;
  void Function(int index, double progress)? onProgress;
  void Function(int index)? onSongCompleted;
  void Function(int index, String reason)? onSongFailed;
  void Function()? onSessionCompleted;
  void Function(String message)? onError;

  // ── Sender side ───────────────────────────────────────────────────────────

  /// Begin advertising so receivers can discover this device.
  Future<void> startAdvertising(List<SongModel> songs) async {
    _songs = songs;
    _isActive = true;

    try {
      await Nearby().startAdvertising(
        _deviceName(),
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResultCallback,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      AppLogger.info('Nearby: advertising started', tag: _tag);
    } catch (e, st) {
      AppLogger.error('startAdvertising', tag: _tag, error: e, stackTrace: st);
      onError?.call('Failed to start advertising: $e');
      rethrow;
    }
  }

  /// Accept an incoming connection request (called by BLoC on user confirm).
  void acceptConnection(String endpointId) {
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }

  /// Reject an incoming connection request.
  void rejectConnection(String endpointId) {
    Nearby().rejectConnection(endpointId);
  }

  /// Send all selected songs to the connected endpoint.
  Future<void> sendSongs(String endpointId) async {
    for (int i = 0; i < _songs.length; i++) {
      final song = _songs[i];
      try {
        final file = File(song.data);
        if (!await file.exists()) {
          onSongFailed?.call(i, 'File not found: ${song.title}');
          continue;
        }

        // First send a metadata bytes payload: "index|filename|title"
        final meta =
            '$i|${song.data.split('/').last}|${song.title}'.codeUnits;
        await Nearby().sendBytesPayload(
          endpointId,
          Uint8List.fromList(meta),
        );

        // Then send the actual file
        await Nearby().sendFilePayload(endpointId, song.data);

        AppLogger.debug(
          'Sent file ${i + 1}/${_songs.length}: ${song.title}',
          tag: _tag,
        );
      } catch (e, st) {
        AppLogger.error(
          'sendSongs index $i',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
        onSongFailed?.call(i, e.toString());
      }
    }
  }

  // ── Receiver side ─────────────────────────────────────────────────────────

  /// Start discovery mode to find advertising senders.
  Future<void> startDiscovery() async {
    _isActive = true;
    try {
      await Nearby().startDiscovery(
        _deviceName(),
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          AppLogger.debug('Endpoint found: $name ($id)', tag: _tag);
          onEndpointFound?.call(id, name);
        },
        onEndpointLost: (id) {
          AppLogger.debug('Endpoint lost: $id', tag: _tag);
          if (id != null) onEndpointLost?.call(id);
        },
        serviceId: _serviceId,
      );
      AppLogger.info('Nearby: discovery started', tag: _tag);
    } catch (e, st) {
      AppLogger.error('startDiscovery', tag: _tag, error: e, stackTrace: st);
      onError?.call('Failed to start discovery: $e');
      rethrow;
    }
  }

  /// Request a connection to a discovered sender.
  Future<void> requestConnection(String endpointId, String name) async {
    try {
      await Nearby().requestConnection(
        _deviceName(),
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResultCallback,
        onDisconnected: _onDisconnected,
      );
    } catch (e, st) {
      AppLogger.error(
        'requestConnection to $endpointId',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Shared callbacks ──────────────────────────────────────────────────────

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    AppLogger.debug(
      'Connection initiated: $id (${info.endpointName})',
      tag: _tag,
    );
    // On the sender side we need BLoC to ask the user to confirm.
    onConnectionRequested?.call(id, info.endpointName);
  }

  void _onConnectionResultCallback(String id, Status status) {
    final success = status == Status.CONNECTED;
    AppLogger.debug(
      'Connection result for $id: ${success ? "CONNECTED" : "FAILED"}',
      tag: _tag,
    );
    onConnectionResult?.call(id, success);

    // If sender and connection succeeded → start sending
    if (success && _songs.isNotEmpty) {
      sendSongs(id);
    }
  }

  void _onDisconnected(String id) {
    AppLogger.debug('Disconnected from $id', tag: _tag);
    if (_isActive) {
      onError?.call('Disconnected from peer');
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type == PayloadType.BYTES) {
      // Parse metadata: "index|filename|title"
      final raw = String.fromCharCodes(payload.bytes!);
      final parts = raw.split('|');
      if (parts.length >= 3) {
        final index = int.tryParse(parts[0]) ?? 0;
        final filename = parts[1];
        _incoming[payload.id] = _IncomingFile(
          index: index,
          filename: filename,
        );
        AppLogger.debug('Meta received for song $index: $filename', tag: _tag);
      }
    } else if (payload.type == PayloadType.FILE) {
      // The file payload arrives; mark it linked to the preceding metadata
      final meta = _incoming[payload.id];
      // Use uri (Android 10+) with filePath as fallback for older devices
      // ignore: deprecated_member_use
      final path = payload.uri ?? payload.filePath;
      if (meta != null && path != null) {
        await _saveReceivedFile(
          sourcePath: path,
          filename: meta.filename,
          songIndex: meta.index,
        );
      }
    }
  }

  void _onPayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    final meta = _incoming[update.id];
    if (meta == null) return;

    if (update.totalBytes > 0) {
      final progress = update.bytesTransferred / update.totalBytes;
      onProgress?.call(meta.index, progress);
    }

    if (update.status == PayloadStatus.SUCCESS) {
      onSongCompleted?.call(meta.index);
      _incoming.remove(update.id);

      // Check if all songs received
      final allDone = _incoming.isEmpty;
      if (allDone && meta.index == (_songs.isNotEmpty ? _songs.length - 1 : 0)) {
        onSessionCompleted?.call();
      }
    } else if (update.status == PayloadStatus.FAILURE) {
      onSongFailed?.call(meta.index, 'Transfer failed');
      _incoming.remove(update.id);
    }
  }

  Future<void> _saveReceivedFile({
    required String sourcePath,
    required String filename,
    required int songIndex,
  }) async {
    try {
      final dir = await _getDownloadDir();
      final dest = File('${dir.path}/$filename');
      await File(sourcePath).copy(dest.path);
      AppLogger.info('Saved song to ${dest.path}', tag: _tag);
      onSongCompleted?.call(songIndex);
    } catch (e, st) {
      AppLogger.error(
        '_saveReceivedFile for $filename',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      onSongFailed?.call(songIndex, e.toString());
    }
  }

  Future<Directory> _getDownloadDir() async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/MusicPlayerTransfer');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _deviceName() =>
      'MusicPlayer-${DateTime.now().millisecondsSinceEpoch % 10000}';

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    if (!_isActive) return;
    _isActive = false;
    try {
      await Nearby().stopAllEndpoints();
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
    } catch (e) {
      AppLogger.warning('NearbyTransferService dispose: $e', tag: _tag);
    }
    _songs = [];
    _incoming.clear();
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _IncomingFile {
  _IncomingFile({required this.index, required this.filename});
  final int index;
  final String filename;
}
