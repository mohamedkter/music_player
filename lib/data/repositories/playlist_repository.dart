import '../models/playlist_model.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract interface class PlaylistRepository {
  Future<Either<Failure, List<PlaylistModel>>> getAllPlaylists();
  Future<Either<Failure, PlaylistModel>> getPlaylistById(int id);
  Future<Either<Failure, PlaylistModel>> createPlaylist(String name);
  Future<Either<Failure, PlaylistModel>> renamePlaylist(int id, String name);
  Future<Either<Failure, void>> deletePlaylist(int id);
  Future<Either<Failure, void>> addSongToPlaylist(int playlistId, int songId);
  Future<Either<Failure, void>> removeSongFromPlaylist(int playlistId, int songId);
  Future<Either<Failure, void>> reorderPlaylist(int playlistId, int oldIndex, int newIndex);
  Stream<List<PlaylistModel>> watchPlaylists();
}
