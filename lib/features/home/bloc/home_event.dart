part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

final class HomeLoadRequested extends HomeEvent {}

final class HomeRefreshRequested extends HomeEvent {}

final class HomeFilterChanged extends HomeEvent {
  const HomeFilterChanged(this.filter);
  final HomeFilter filter;
  @override
  List<Object?> get props => [filter];
}
