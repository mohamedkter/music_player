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
