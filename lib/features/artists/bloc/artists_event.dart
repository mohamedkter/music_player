part of 'artists_bloc.dart';

sealed class ArtistsEvent extends Equatable {
  const ArtistsEvent();
  @override
  List<Object?> get props => [];
}

final class ArtistsLoadRequested extends ArtistsEvent {}

final class ArtistsSearchChanged extends ArtistsEvent {
  const ArtistsSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class ArtistsSearchCleared extends ArtistsEvent {}
