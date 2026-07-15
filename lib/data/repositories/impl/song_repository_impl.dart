import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../../datasources/local_song_datasource.dart';
import '../../datasources/preferences_datasource.dart';
import '../../models/song_model.dart';
import '../song_repository.dart';

/// Concrete implementation of [SongRepository].
/// All exceptions are caught here and converted to [Failure]s.
/// BLoCs only see the abstract [SongRepository] interface.
class SongRepositoryImpl implements SongRepository {
  SongRepositoryImpl({
    required LocalSongDataSource dataSource,
    required PreferencesDataSource prefs,
  })  : _dataSource = dataSource,
        _prefs = prefs;

  final LocalSongDataSource _dataSource;
  final PreferencesDataSource _prefs;
  static const _tag = 'SongRepositoryImpl';

  // In-memory cache — invalidated on scanLibrary()
  List<SongModel>? _cache;

  // StreamController for reactive favorites
  final _favoritesController =
      StreamController<List<SongModel>>.broadcast();

  @override
  Future<Either<Failure, List<SongModel>>> getAllSongs({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final songs = await _fetch();
        if (songs.isEmpty) return right(_cache ?? []);
        final currentList = _cache ?? await _loadCacheFromDisk() ?? [];
        final songsWithMeta = _mergeMetadata(songs, currentList);
        _cache = songsWithMeta;
        await _saveCacheToDisk(songsWithMeta);
        return right(songsWithMeta);
      }

      if (_cache == null || _cache!.isEmpty) {
        final diskSongs = await _loadCacheFromDisk();
        if (diskSongs != null && diskSongs.isNotEmpty) {
          _cache = diskSongs;
          return right(_cache!);
        }

        final songs = await _fetch();
        // Only cache if we got actual results — empty likely means
        // MediaStore hasn't synced yet (e.g. right after permission grant).
        if (songs.isNotEmpty) {
          _cache = songs;
          await _saveCacheToDisk(songs);
        }
        return right(songs);
      }
      return right(_cache!);
    } on PermissionException catch (e) {
      return left(PermissionFailure(e.message));
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('getAllSongs', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SongModel>>> searchSongs(String query) async {
    final result = await getAllSongs();
    return result.map(
      (songs) => songs
          .where(
            (s) =>
                s.title.toLowerCase().contains(query.toLowerCase()) ||
                s.artist.toLowerCase().contains(query.toLowerCase()) ||
                s.album.toLowerCase().contains(query.toLowerCase()),
          )
          .toList(),
    );
  }

  @override
  Future<Either<Failure, List<SongModel>>> getRecentlyPlayed({
    int limit = 20,
  }) async {
    final result = await getAllSongs();
    return result.map((songs) {
      final sorted = songs.where((s) => s.lastPlayed > 0).toList()
        ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
      return sorted.take(limit).toList();
    });
  }

  @override
  Future<Either<Failure, List<SongModel>>> getMostPlayed({
    int limit = 20,
  }) async {
    final result = await getAllSongs();
    return result.map((songs) {
      final sorted = songs.where((s) => s.playCount > 0).toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount));
      return sorted.take(limit).toList();
    });
  }

  @override
  Future<Either<Failure, List<SongModel>>> getRecentlyAdded({
    int limit = 30,
  }) async {
    final result = await getAllSongs();
    return result.map((songs) {
      final sorted = List<SongModel>.from(songs)
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return sorted.take(limit).toList();
    });
  }

  @override
  Future<Either<Failure, List<SongModel>>> getFavorites() async {
    final result = await getAllSongs();
    return result.map(
      (songs) => songs.where((s) => s.isFavorite).toList(),
    );
  }

  @override
  Future<Either<Failure, List<SongModel>>> getSongsByAlbum(
    int albumId,
  ) async {
    try {
      final songs = await _dataSource.fetchSongsByAlbum(albumId);
      return right(songs);
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('getSongsByAlbum', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SongModel>>> getSongsByArtist(
    int artistId,
  ) async {
    try {
      final songs = await _dataSource.fetchSongsByArtist(artistId);
      return right(songs);
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('getSongsByArtist', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SongModel>>> getSongsByFolder(
    String folderPath,
  ) async {
    final result = await getAllSongs();
    return result.map(
      (songs) =>
          songs.where((s) => s.folderPath == folderPath).toList(),
    );
  }

  @override
  Future<Either<Failure, SongModel>> toggleFavorite(int songId) async {
    try {
      final result = await getAllSongs();
      return result.fold(
        left,
        (songs) {
          final idx = songs.indexWhere((s) => s.id == songId);
          if (idx < 0) return left(const NotFoundFailure());
          final updated = songs[idx].copyWith(
            isFavorite: !songs[idx].isFavorite,
          );
          _cache![idx] = updated;
          _saveCacheToDisk(_cache!);
          _pushFavorites(_cache!);
          return right(updated);
        },
      );
    } catch (e, st) {
      AppLogger.error('toggleFavorite', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordPlay(int songId) async {
    try {
      final result = await getAllSongs();
      result.fold((_) {}, (songs) {
        final idx = songs.indexWhere((s) => s.id == songId);
        if (idx >= 0) {
          _cache![idx] = songs[idx].copyWith(
            playCount: songs[idx].playCount + 1,
            lastPlayed: DateTime.now().millisecondsSinceEpoch,
          );
          _saveCacheToDisk(_cache!);
        }
      });
      return right(null);
    } catch (e, st) {
      AppLogger.error('recordPlay', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> scanLibrary() async {
    try {
      final currentList = _cache ?? await _loadCacheFromDisk() ?? [];
      _cache = null; // Invalidate
      final songs = await _fetch();
      final songsWithMeta = _mergeMetadata(songs, currentList);
      _cache = songsWithMeta;
      await _saveCacheToDisk(songsWithMeta);
      AppLogger.info(
        'Library scan complete: ${songsWithMeta.length} songs',
        tag: _tag,
      );
      return right(songsWithMeta.length);
    } on PermissionException catch (e) {
      return left(PermissionFailure(e.message));
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('scanLibrary', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<List<SongModel>> watchFavorites() => _favoritesController.stream;

  @override
  Future<Either<Failure, List<SongModel>>> getAllVideos() async {
    try {
      final videos = await _dataSource.fetchAllVideos();
      return right(videos);
    } catch (e, st) {
      AppLogger.error('getAllVideos', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  void dispose() => _favoritesController.close();

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<SongModel>> _fetch() {
    return _dataSource.fetchAllSongs(
      minDurationSeconds: _prefs.getIgnoreShortAudio()
          ? _prefs.getMinAudioDuration()
          : 0,
      excludedFolders: _prefs.getExcludedFolders(),
    );
  }

  void _pushFavorites(List<SongModel> songs) {
    if (!_favoritesController.isClosed) {
      _favoritesController
          .add(songs.where((s) => s.isFavorite).toList());
    }
  }

  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/songs_cache.json');
  }

  Future<void> _saveCacheToDisk(List<SongModel> songs) async {
    try {
      final file = await _getCacheFile();
      final maps = songs.map((s) => s.toMap()).toList();
      final jsonStr = json.encode(maps);
      await file.writeAsString(jsonStr);
      AppLogger.info('Saved ${songs.length} songs to disk cache', tag: _tag);
    } catch (e, st) {
      AppLogger.error('Failed to save disk cache', tag: _tag, error: e, stackTrace: st);
    }
  }

  Future<List<SongModel>?> _loadCacheFromDisk() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) return null;
      final jsonStr = await file.readAsString();
      final decoded = json.decode(jsonStr) as List<dynamic>;
      final songs = decoded.map((m) => SongModel.fromMap(m as Map<String, dynamic>)).toList();
      AppLogger.info('Loaded ${songs.length} songs from disk cache', tag: _tag);
      return songs;
    } catch (e, st) {
      AppLogger.error('Failed to load disk cache', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  List<SongModel> _mergeMetadata(List<SongModel> fresh, List<SongModel> current) {
    if (current.isEmpty) return fresh;
    final currentMap = {for (final s in current) s.data: s};
    return fresh.map((f) {
      final cur = currentMap[f.data];
      if (cur != null) {
        return f.copyWith(
          playCount: cur.playCount,
          lastPlayed: cur.lastPlayed,
          isFavorite: cur.isFavorite,
        );
      }
      return f;
    }).toList();
  }
}
