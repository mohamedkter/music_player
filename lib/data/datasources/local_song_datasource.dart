import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../models/song_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Reads song data from Android MediaStore via [on_audio_query].
/// The only place in the codebase that knows about the [oaq] package.
class LocalSongDataSource {
  LocalSongDataSource() : _query = oaq.OnAudioQuery();

  final oaq.OnAudioQuery _query;
  static const String _tag = 'LocalSongDataSource';

  Future<List<SongModel>> fetchAllSongs({
    int minDurationSeconds = AppConstants.minTrackDurationSeconds,
    List<String> excludedFolders = const [],
  }) async {
    try {
      await _ensurePermission();

      final raw = await _query.querySongs(
        sortType: oaq.SongSortType.TITLE,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
        uriType: oaq.UriType.EXTERNAL,
        ignoreCase: true,
      );
      AppLogger.info('Raw songs: ${raw.length}', tag: _tag);

      final result = raw
          .where((s) => _isValid(s, minDurationSeconds, excludedFolders))
          .map(_toModel)
          .toList();

      AppLogger.info('After filtering: ${result.length}', tag: _tag);
      return result;
    } catch (e, st) {
      AppLogger.error('fetchAllSongs', tag: _tag, error: e, stackTrace: st);
      throw MediaScanException('$e');
    }
  }

  Future<void>? _permissionFuture;

  /// Checks if the app has media/storage permission.
  /// Requests it if missing. Throws [MediaScanException] if denied.
  /// Uses a shared future to prevent concurrent method channel requests.
  Future<void> _ensurePermission() {
    _permissionFuture ??= _checkAndRequestPermission();
    return _permissionFuture!;
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      final hasPermission = await _query.permissionsStatus();
      if (!hasPermission) {
        final granted = await _query.permissionsRequest();
        if (!granted) {
          AppLogger.warning('Audio permission denied', tag: _tag);
          throw MediaScanException('Audio permission denied by user');
        }
        // Wait 1000ms for Android MediaStore to sync and update its cache
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      }
    } catch (e) {
      _permissionFuture = null; // Reset so next attempt can retry
      rethrow;
    }
  }

  Future<List<SongModel>> fetchSongsByAlbum(int albumId) async {
    try {
      await _ensurePermission();
      final raw = await _query.queryAudiosFrom(
        oaq.AudiosFromType.ALBUM_ID,
        albumId,
        sortType: oaq.SongSortType.DATE_ADDED,
      );
      return raw.map(_toModel).toList();
    } catch (e, st) {
      AppLogger.error('fetchSongsByAlbum', tag: _tag, error: e, stackTrace: st);
      throw MediaScanException('$e');
    }
  }

  Future<List<SongModel>> fetchSongsByArtist(int artistId) async {
    try {
      await _ensurePermission();
      final raw = await _query.queryAudiosFrom(
        oaq.AudiosFromType.ARTIST_ID,
        artistId,
      );
      return raw.map(_toModel).toList();
    } catch (e, st) {
      AppLogger.error('fetchSongsByArtist', tag: _tag, error: e, stackTrace: st);
      throw MediaScanException('$e');
    }
  }

  /// Scans known video directories on Android for video files.
  /// Only scans DCIM, Movies, Video, Videos, Download — not the entire storage.
  Future<List<SongModel>> fetchAllVideos() async {
    try {
      await _ensurePermission();

      // Known external storage roots on Android
      const roots = ['/storage/emulated/0', '/sdcard'];

      // Directories that commonly contain videos on Android
      const videoDirs = [
        'DCIM',
        'Movies',
        'Movie',
        'Video',
        'Videos',
        'Download',
        'Downloads',
        'WhatsApp/Media/WhatsApp Video',
        'Telegram/Telegram Video',
      ];

      final videoFiles = <File>[];

      for (final root in roots) {
        if (!Directory(root).existsSync()) continue;

        for (final sub in videoDirs) {
          final dir = Directory('$root/$sub');
          if (!dir.existsSync()) continue;
          await _scanDirForVideos(dir, videoFiles, maxDepth: 3);
        }
        break; // Only scan the first valid root
      }

      AppLogger.info('Videos found: ${videoFiles.length}', tag: _tag);

      final result = <SongModel>[];
      var idCounter = -1;
      for (final file in videoFiles) {
        try {
          final stat = await file.stat();
          final name = file.path.split('/').last;
          final nameWithoutExt = name.contains('.')
              ? name.substring(0, name.lastIndexOf('.'))
              : name;
          result.add(SongModel(
            id: idCounter--,
            title: nameWithoutExt,
            artist: 'Unknown Artist',
            album: 'Videos',
            data: file.path,
            duration: 0,
            size: stat.size,
            dateAdded: stat.modified.millisecondsSinceEpoch ~/ 1000,
          ));
        } catch (_) {}
      }
      return result;
    } catch (e, st) {
      AppLogger.error('fetchAllVideos', tag: _tag, error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> _scanDirForVideos(
    Directory dir,
    List<File> result, {
    int depth = 0,
    int maxDepth = 3,
  }) async {
    if (depth > maxDepth) return;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (AppConstants.supportedVideoFormats.contains(ext)) {
            result.add(entity);
          }
        } else if (entity is Directory) {
          final name = entity.path.split('/').last;
          if (!name.startsWith('.')) {
            await _scanDirForVideos(entity, result,
                depth: depth + 1, maxDepth: maxDepth);
          }
        }
      }
    } catch (_) {}
  }

  // ── Private ───────────────────────────────────────────────────────────────

  bool _isValid(
    oaq.SongModel s,
    int minDurationSeconds,
    List<String> excludedFolders,
  ) {
    final data = s.data;
    final duration = s.duration ?? 0;

    if (duration < minDurationSeconds * 1000) return false;

    for (final folder in excludedFolders) {
      if (data.startsWith(folder)) return false;
    }

    final ext = s.fileExtension.toLowerCase();
    return AppConstants.supportedAudioFormats.contains(ext);
  }

  SongModel _toModel(oaq.SongModel s) {
    return SongModel(
      id: s.id,
      title: s.title,
      artist: s.artist ?? 'Unknown Artist',
      album: s.album ?? 'Unknown Album',
      data: s.data,
      duration: s.duration ?? 0,
      size: s.size,
      dateAdded: s.dateAdded ?? 0,
      genre: s.genre,
      track: s.track,
    );
  }
}
