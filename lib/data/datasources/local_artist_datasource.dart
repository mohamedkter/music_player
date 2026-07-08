import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../models/artist_model.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Reads artist data from Android MediaStore via [on_audio_query].
class LocalArtistDataSource {
  LocalArtistDataSource() : _query = oaq.OnAudioQuery();

  final oaq.OnAudioQuery _query;
  static const String _tag = 'LocalArtistDataSource';

  Future<List<ArtistModel>> fetchAllArtists() async {
    try {
      final raw = await _query.queryArtists(
        sortType: oaq.ArtistSortType.ARTIST,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
      );
      return raw.map(_toModel).toList();
    } catch (e, st) {
      AppLogger.error('fetchAllArtists failed', tag: _tag, error: e, stackTrace: st);
      throw MediaScanException('$e');
    }
  }

  Future<List<ArtistModel>> searchArtists(String query) async {
    final all = await fetchAllArtists();
    final q = query.toLowerCase();
    return all.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  ArtistModel _toModel(oaq.ArtistModel a) {
    return ArtistModel(
      id: a.id,
      name: a.artist,
      numberOfTracks: a.numberOfTracks ?? 0,
      numberOfAlbums: a.numberOfAlbums ?? 0,
    );
  }
}
