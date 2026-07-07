import '../models/song_model.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

/// Abstract contract for all song data operations.
/// BLoCs depend on this interface — never on concrete implementations.
/// Follows Dependency Inversion Principle.
abstract interface class SongRepository {
  /// Returns all songs from local storage.
  Future<Either<Failure, List<SongModel>>> getAllSongs();

  /// Returns songs sorted/filtered by [query].
  Future<Either<Failure, List<SongModel>>> searchSongs(String query);

  /// Returns recently played songs, limited to [limit].
  Future<Either<Failure, List<SongModel>>> getRecentlyPlayed({int limit = 20});

  /// Returns most played songs by play count.
  Future<Either<Failure, List<SongModel>>> getMostPlayed({int limit = 20});

  /// Returns songs added most recently to the device.
  Future<Either<Failure, List<SongModel>>> getRecentlyAdded({int limit = 30});

  /// Returns all songs marked as favorite.
  Future<Either<Failure, List<SongModel>>> getFavorites();

  /// Returns songs belonging to [albumId].
  Future<Either<Failure, List<SongModel>>> getSongsByAlbum(int albumId);

  /// Returns songs belonging to [artistId].
  Future<Either<Failure, List<SongModel>>> getSongsByArtist(int artistId);

  /// Returns songs in [folderPath].
  Future<Either<Failure, List<SongModel>>> getSongsByFolder(String folderPath);

  /// Toggles the favorite flag for [songId].
  Future<Either<Failure, SongModel>> toggleFavorite(int songId);

  /// Increments the play count and updates lastPlayed timestamp.
  Future<Either<Failure, void>> recordPlay(int songId);

  /// Scans the device MediaStore and syncs with local DB.
  Future<Either<Failure, int>> scanLibrary();

  /// Watches favorite changes as a reactive stream.
  Stream<List<SongModel>> watchFavorites();
}
