part of 'home_bloc.dart';

sealed class HomeEvent {}

final class HomeLoadRequested extends HomeEvent {}

final class HomeRefreshRequested extends HomeEvent {}
