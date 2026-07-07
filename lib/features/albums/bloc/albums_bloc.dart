import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '../../../data/models/album_model.dart';
import '../../../data/repositories/album_repository.dart';
import '../../../core/utils/logger.dart';

part 'albums_event.dart';
part 'albums_state.dart';

class AlbumsBloc extends Bloc<AlbumsEvent, AlbumsState> {
  AlbumsBloc(this._repository) : super(AlbumsInitial()) {
    on<AlbumsLoadRequested>(_onLoad);
    on<AlbumsSearchChanged>(
      _onSearch,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<AlbumsSearchCleared>(_onSearchCleared);
  }

  final AlbumRepository _repository;
  static const _tag = 'AlbumsBloc';

  Future<void> _onLoad(
    AlbumsLoadRequested event,
    Emitter<AlbumsState> emit,
  ) async {
    emit(AlbumsLoading());
    final result = await _repository.getAllAlbums();
    result.fold(
      (f) {
        AppLogger.error(f.message, tag: _tag);
        emit(AlbumsError(f.message));
      },
      (albums) => emit(AlbumsLoaded(albums: albums, allAlbums: albums)),
    );
  }

  void _onSearch(AlbumsSearchChanged event, Emitter<AlbumsState> emit) {
    if (state is! AlbumsLoaded) return;
    final current = state as AlbumsLoaded;
    final q = event.query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? current.allAlbums
        : current.allAlbums
            .where(
              (a) =>
                  a.title.toLowerCase().contains(q) ||
                  a.artist.toLowerCase().contains(q),
            )
            .toList();
    emit(current.copyWith(albums: filtered, searchQuery: event.query));
  }

  void _onSearchCleared(AlbumsSearchCleared event, Emitter<AlbumsState> emit) {
    if (state is! AlbumsLoaded) return;
    final current = state as AlbumsLoaded;
    emit(current.copyWith(albums: current.allAlbums, searchQuery: ''));
  }
}
