import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../core/utils/logger.dart';

part 'songs_event.dart';
part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  SongsBloc(this._repository) : super(SongsInitial()) {
    on<SongsLoadRequested>(_onLoad);
    on<SongsSearchChanged>(
      _onSearch,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<SongsSearchCleared>(_onSearchCleared);
    on<SongsSortChanged>(_onSortChanged);
    on<SongFavoriteToggled>(_onFavoriteToggled);
  }

  final SongRepository _repository;
  static const _tag = 'SongsBloc';

  Future<void> _onLoad(
    SongsLoadRequested event,
    Emitter<SongsState> emit,
  ) async {
    emit(SongsLoading());
    final result = await _repository.getAllSongs();
    result.fold(
      (failure) {
        AppLogger.error('Load songs failed: ${failure.message}', tag: _tag);
        emit(SongsError(failure.message));
      },
      (songs) {
        final sorted = _sort(songs, SongSortOption.dateNewest);
        emit(SongsLoaded(
          songs: sorted,
          allSongs: songs,
          sort: SongSortOption.dateNewest,
        ));
      },
    );
  }

  void _onSearch(
    SongsSearchChanged event,
    Emitter<SongsState> emit,
  ) {
    if (state is! SongsLoaded) return;
    final current = state as SongsLoaded;
    final query = event.query.trim().toLowerCase();

    final filtered = query.isEmpty
        ? current.allSongs
        : current.allSongs.where(
            (s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query) ||
                s.album.toLowerCase().contains(query),
          ).toList();

    emit(current.copyWith(
      songs: _sort(filtered, current.sort),
      searchQuery: event.query,
    ));
  }

  void _onSearchCleared(
    SongsSearchCleared event,
    Emitter<SongsState> emit,
  ) {
    if (state is! SongsLoaded) return;
    final current = state as SongsLoaded;
    emit(current.copyWith(
      songs: _sort(current.allSongs, current.sort),
      searchQuery: '',
    ));
  }

  void _onSortChanged(
    SongsSortChanged event,
    Emitter<SongsState> emit,
  ) {
    if (state is! SongsLoaded) return;
    final current = state as SongsLoaded;
    emit(current.copyWith(
      songs: _sort(current.songs, event.sort),
      sort: event.sort,
    ));
  }

  Future<void> _onFavoriteToggled(
    SongFavoriteToggled event,
    Emitter<SongsState> emit,
  ) async {
    if (state is! SongsLoaded) return;
    final result = await _repository.toggleFavorite(event.songId);
    result.fold(
      (f) => AppLogger.warning(f.message, tag: _tag),
      (updated) {
        final current = state as SongsLoaded;
        final update = (List<SongModel> list) => list.map(
              (s) => s.id == updated.id ? updated : s,
            ).toList();
        emit(current.copyWith(
          songs: update(current.songs),
          allSongs: update(current.allSongs),
        ));
      },
    );
  }

  // ── Sort helper ───────────────────────────────────────────────────────────
  List<SongModel> _sort(List<SongModel> songs, SongSortOption opt) {
    final list = List<SongModel>.from(songs);
    switch (opt) {
      case SongSortOption.titleAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
      case SongSortOption.titleDesc:
        list.sort((a, b) => b.title.compareTo(a.title));
      case SongSortOption.artistAsc:
        list.sort((a, b) => a.artist.compareTo(b.artist));
      case SongSortOption.albumAsc:
        list.sort((a, b) => a.album.compareTo(b.album));
      case SongSortOption.dateNewest:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case SongSortOption.dateOldest:
        list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      case SongSortOption.durationLongest:
        list.sort((a, b) => b.duration.compareTo(a.duration));
      case SongSortOption.durationShortest:
        list.sort((a, b) => a.duration.compareTo(b.duration));
    }
    return list;
  }
}
