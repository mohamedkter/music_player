part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.recentlyPlayed,
    required this.mostPlayed,
    required this.favorites,
    required this.recentlyAdded,
  });

  final List<SongModel> recentlyPlayed;
  final List<SongModel> mostPlayed;
  final List<SongModel> favorites;
  final List<SongModel> recentlyAdded;

  @override
  List<Object?> get props =>
      [recentlyPlayed, mostPlayed, favorites, recentlyAdded];
}

final class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
