import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../models/album_model.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Reads album data from Android MediaStore via [on_audio_query].
class LocalAlbumDataSource {
  LocalAlbumDataSource() : _query = oaq.OnAudioQuery();

  final oaq.OnAudioQuery _query;
  static const String _tag = 'LocalAlbumDataSource';

  Future<List<AlbumModel>> fetchAllAlbums() async {
    try {
      final raw = await _query.queryAlbums(
        sortType: oaq.AlbumSortType.ALBUM,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
      );
      return raw.map(_toModel).toList();
    } catch (e, st) {
      AppLogger.error('fetchAllAlbums failed', tag: _tag, error: e, stackTrace: st);
      throw MediaScanException('$e');
    }
  }

  AlbumModel _toModel(oaq.AlbumModel a) {
    return AlbumModel(
      id: a.id,
      title: a.album,
      artist: a.artist ?? 'Unknown Artist',
      numberOfSongs: a.numOfSongs,
      year: null,
    );
  }
}
