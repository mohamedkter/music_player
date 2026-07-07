import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../core/utils/logger.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
  }

  final SongRepository _repository;
  static const _tag = 'HomeBloc';

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // Run all queries concurrently for faster load
      final results = await Future.wait([
        _repository.getRecentlyPlayed(limit: 10),
        _repository.getMostPlayed(limit: 10),
        _repository.getFavorites(),
        _repository.getRecentlyAdded(limit: 20),
      ]);

      // fold each — if any fails we fall back to empty list
      final recentlyPlayed = results[0].fold((_) => <SongModel>[], (s) => s);
      final mostPlayed = results[1].fold((_) => <SongModel>[], (s) => s);
      final favorites = results[2].fold((_) => <SongModel>[], (s) => s);
      final recentlyAdded = results[3].fold((_) => <SongModel>[], (s) => s);

      emit(HomeLoaded(
        recentlyPlayed: recentlyPlayed,
        mostPlayed: mostPlayed,
        favorites: favorites,
        recentlyAdded: recentlyAdded,
      ));
    } catch (e, st) {
      AppLogger.error('HomeBloc load', tag: _tag, error: e, stackTrace: st);
      emit(HomeError(e.toString()));
    }
  }
}
