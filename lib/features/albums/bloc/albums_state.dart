part of 'albums_bloc.dart';

sealed class AlbumsState extends Equatable {
  const AlbumsState();
  @override
  List<Object?> get props => [];
}

final class AlbumsInitial extends AlbumsState {}

final class AlbumsLoading extends AlbumsState {}

final class AlbumsLoaded extends AlbumsState {
  const AlbumsLoaded({
    required this.albums,
    required this.allAlbums,
    this.searchQuery = '',
  });

  final List<AlbumModel> albums;
  final List<AlbumModel> allAlbums;
  final String searchQuery;

  AlbumsLoaded copyWith({
    List<AlbumModel>? albums,
    List<AlbumModel>? allAlbums,
    String? searchQuery,
  }) {
    return AlbumsLoaded(
      albums: albums ?? this.albums,
      allAlbums: allAlbums ?? this.allAlbums,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [albums, allAlbums, searchQuery];
}

final class AlbumsError extends AlbumsState {
  const AlbumsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
