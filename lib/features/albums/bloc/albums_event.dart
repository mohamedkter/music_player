part of 'albums_bloc.dart';

sealed class AlbumsEvent {}

final class AlbumsLoadRequested extends AlbumsEvent {}

final class AlbumsSearchChanged extends AlbumsEvent {
  AlbumsSearchChanged(this.query);
  final String query;
}

final class AlbumsSearchCleared extends AlbumsEvent {}
