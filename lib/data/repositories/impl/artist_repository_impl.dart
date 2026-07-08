import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../../datasources/local_artist_datasource.dart';
import '../../models/artist_model.dart';
import '../artist_repository.dart';

/// Concrete implementation of [ArtistRepository] backed by [LocalArtistDataSource].
class ArtistRepositoryImpl implements ArtistRepository {
  ArtistRepositoryImpl({required LocalArtistDataSource dataSource})
      : _dataSource = dataSource;

  final LocalArtistDataSource _dataSource;
  static const _tag = 'ArtistRepositoryImpl';

  // Simple in-memory cache
  List<ArtistModel>? _cache;

  @override
  Future<Either<Failure, List<ArtistModel>>> getAllArtists() async {
    try {
      _cache ??= await _dataSource.fetchAllArtists();
      return right(_cache!);
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('getAllArtists', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ArtistModel>> getArtistById(int id) async {
    final result = await getAllArtists();
    return result.fold(
      left,
      (artists) {
        try {
          return right(artists.firstWhere((a) => a.id == id));
        } catch (_) {
          return left(const NotFoundFailure());
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<ArtistModel>>> searchArtists(String query) async {
    try {
      final results = await _dataSource.searchArtists(query);
      return right(results);
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('searchArtists', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }
}
