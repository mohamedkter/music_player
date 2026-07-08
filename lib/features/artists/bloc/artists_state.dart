part of 'artists_bloc.dart';

sealed class ArtistsState extends Equatable {
  const ArtistsState();
  @override
  List<Object?> get props => [];
}

final class ArtistsInitial extends ArtistsState {}

final class ArtistsLoading extends ArtistsState {}

final class ArtistsLoaded extends ArtistsState {
  const ArtistsLoaded({
    required this.artists,
    required this.allArtists,
    this.searchQuery = '',
  });

  final List<ArtistModel> artists;
  final List<ArtistModel> allArtists;
  final String searchQuery;

  ArtistsLoaded copyWith({
    List<ArtistModel>? artists,
    List<ArtistModel>? allArtists,
    String? searchQuery,
  }) {
    return ArtistsLoaded(
      artists: artists ?? this.artists,
      allArtists: allArtists ?? this.allArtists,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [artists, allArtists, searchQuery];
}

final class ArtistsError extends ArtistsState {
  const ArtistsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
