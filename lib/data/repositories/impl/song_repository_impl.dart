import 'dart:async';
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
  Future<Either<Failure, List<SongModel>>> getAllSongs() async {
    try {
      if (_cache == null || _cache!.isEmpty) {
        final songs = await _fetch();
        // Only cache if we got actual results — empty likely means
        // MediaStore hasn't synced yet (e.g. right after permission grant).
        if (songs.isNotEmpty) {
          _cache = songs;
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
      _cache = null; // Invalidate
      final songs = await _fetch();
      _cache = songs;
      AppLogger.info(
        'Library scan complete: ${songs.length} songs',
        tag: _tag,
      );
      return right(songs.length);
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
}
