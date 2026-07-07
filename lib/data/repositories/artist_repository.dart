import '../models/artist_model.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract interface class ArtistRepository {
  Future<Either<Failure, List<ArtistModel>>> getAllArtists();
  Future<Either<Failure, ArtistModel>> getArtistById(int id);
  Future<Either<Failure, List<ArtistModel>>> searchArtists(String query);
}
