import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '../../../data/models/album_model.dart';
import '../../../data/models/artist_model.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../data/repositories/album_repository.dart';
import '../../../data/repositories/artist_repository.dart';
import '../../../core/utils/logger.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required SongRepository songRepository,
    required AlbumRepository albumRepository,
    required ArtistRepository artistRepository,
  })  : _songs = songRepository,
        _albums = albumRepository,
        _artists = artistRepository,
        super(SearchIdle()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 350))
          .distinct()
          .switchMap(mapper),
    );
    on<SearchCleared>(_onCleared);
  }

  final SongRepository _songs;
  final AlbumRepository _albums;
  final ArtistRepository _artists;
  static const _tag = 'SearchBloc';
  static const int _minLength = 2;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final q = event.query.trim();
    if (q.length < _minLength) {
      emit(SearchIdle());
      return;
    }

    emit(SearchLoading());
    try {
      final results = await Future.wait([
        _songs.searchSongs(q),
        _albums.searchAlbums(q),
        _artists.searchArtists(q),
      ]);

      final songs = results[0].fold((_) => <SongModel>[], (v) => v as List<SongModel>);
      final albums = results[1].fold((_) => <AlbumModel>[], (v) => v as List<AlbumModel>);
      final artists = results[2].fold((_) => <ArtistModel>[], (v) => v as List<ArtistModel>);

      emit(SearchResults(
        query: q,
        songs: songs.take(5).toList(),
        albums: albums.take(5).toList(),
        artists: artists.take(5).toList(),
      ));
    } catch (e, st) {
      AppLogger.error('search error', tag: _tag, error: e, stackTrace: st);
      emit(SearchError(e.toString()));
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(SearchIdle());
  }
}
