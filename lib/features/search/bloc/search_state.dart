part of 'search_bloc.dart';

sealed class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

final class SearchIdle extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchResults extends SearchState {
  const SearchResults({
    required this.query,
    required this.songs,
    required this.albums,
    required this.artists,
  });

  final String query;
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;

  bool get isEmpty =>
      songs.isEmpty && albums.isEmpty && artists.isEmpty;

  @override
  List<Object?> get props => [query, songs, albums, artists];
}

final class SearchError extends SearchState {
  const SearchError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
