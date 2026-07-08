import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../../datasources/local_album_datasource.dart';
import '../../models/album_model.dart';
import '../album_repository.dart';

/// Concrete implementation of [AlbumRepository] backed by [LocalAlbumDataSource].
class AlbumRepositoryImpl implements AlbumRepository {
  AlbumRepositoryImpl({required LocalAlbumDataSource dataSource})
      : _dataSource = dataSource;

  final LocalAlbumDataSource _dataSource;
  static const _tag = 'AlbumRepositoryImpl';

  // Simple in-memory cache
  List<AlbumModel>? _cache;

  @override
  Future<Either<Failure, List<AlbumModel>>> getAllAlbums() async {
    try {
      _cache ??= await _dataSource.fetchAllAlbums();
      return right(_cache!);
    } on MediaScanException catch (e) {
      return left(MediaScanFailure(e.message));
    } catch (e, st) {
      AppLogger.error('getAllAlbums', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AlbumModel>> getAlbumById(int id) async {
    final result = await getAllAlbums();
    return result.fold(
      left,
      (albums) {
        try {
          return right(albums.firstWhere((a) => a.id == id));
        } catch (_) {
          return left(const NotFoundFailure());
        }
      },
    );
  }

  @override
  Future<Either<Failure, List<AlbumModel>>> searchAlbums(String query) async {
    final result = await getAllAlbums();
    return result.map((albums) {
      final q = query.toLowerCase();
      return albums
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.artist.toLowerCase().contains(q),
          )
          .toList();
    });
  }
}
