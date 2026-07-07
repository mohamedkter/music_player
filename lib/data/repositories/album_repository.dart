import '../models/album_model.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract interface class AlbumRepository {
  Future<Either<Failure, List<AlbumModel>>> getAllAlbums();
  Future<Either<Failure, AlbumModel>> getAlbumById(int id);
  Future<Either<Failure, List<AlbumModel>>> searchAlbums(String query);
}
