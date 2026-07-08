import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '../../../data/models/artist_model.dart';
import '../../../data/repositories/artist_repository.dart';
import '../../../core/utils/logger.dart';

part 'artists_event.dart';
part 'artists_state.dart';

class ArtistsBloc extends Bloc<ArtistsEvent, ArtistsState> {
  ArtistsBloc(this._repository) : super(ArtistsInitial()) {
    on<ArtistsLoadRequested>(_onLoad);
    on<ArtistsSearchChanged>(
      _onSearch,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<ArtistsSearchCleared>(_onSearchCleared);
  }

  final ArtistRepository _repository;
  static const _tag = 'ArtistsBloc';

  Future<void> _onLoad(
    ArtistsLoadRequested event,
    Emitter<ArtistsState> emit,
  ) async {
    emit(ArtistsLoading());
    final result = await _repository.getAllArtists();
    result.fold(
      (f) {
        AppLogger.error(f.message, tag: _tag);
        emit(ArtistsError(f.message));
      },
      (artists) {
        final sorted = List<ArtistModel>.from(artists)
          ..sort((a, b) => a.name.compareTo(b.name));
        emit(ArtistsLoaded(artists: sorted, allArtists: sorted));
      },
    );
  }

  void _onSearch(ArtistsSearchChanged event, Emitter<ArtistsState> emit) {
    if (state is! ArtistsLoaded) return;
    final current = state as ArtistsLoaded;
    final q = event.query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? current.allArtists
        : current.allArtists
            .where((a) => a.name.toLowerCase().contains(q))
            .toList();
    emit(current.copyWith(artists: filtered, searchQuery: event.query));
  }

  void _onSearchCleared(ArtistsSearchCleared event, Emitter<ArtistsState> emit) {
    if (state is! ArtistsLoaded) return;
    final current = state as ArtistsLoaded;
    emit(current.copyWith(artists: current.allArtists, searchQuery: ''));
  }
}
