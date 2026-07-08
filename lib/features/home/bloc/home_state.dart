part of 'home_bloc.dart';

/// Filter tabs for the media library section.
enum HomeFilter {
  all,
  songs,
  albums,
  artists,
  playlists,
  folders,
  videos,
}

extension HomeFilterLabel on HomeFilter {
  String get label => switch (this) {
        HomeFilter.all => 'ALL',
        HomeFilter.songs => 'SONGS',
        HomeFilter.albums => 'ALBUMS',
        HomeFilter.artists => 'ARTISTS',
        HomeFilter.playlists => 'PLAYLISTS',
        HomeFilter.folders => 'FOLDERS',
        HomeFilter.videos => 'VIDEOS',
      };
}

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
    required this.allSongs,
    required this.playlists,
    required this.albums,
    required this.artists,
    required this.folders,
    required this.videoAudio,
    required this.activeFilter,
  });

  final List<SongModel> recentlyPlayed;
  final List<SongModel> mostPlayed;
  final List<SongModel> favorites;
  final List<SongModel> recentlyAdded;
  final List<SongModel> allSongs;
  final List<PlaylistModel> playlists;
  final List<HomeAlbumEntry> albums;
  final List<HomeArtistEntry> artists;
  final List<HomeFolderEntry> folders;
  final List<SongModel> videoAudio;
  final HomeFilter activeFilter;

  HomeLoaded copyWith({
    List<SongModel>? recentlyPlayed,
    List<SongModel>? mostPlayed,
    List<SongModel>? favorites,
    List<SongModel>? recentlyAdded,
    List<SongModel>? allSongs,
    List<PlaylistModel>? playlists,
    List<HomeAlbumEntry>? albums,
    List<HomeArtistEntry>? artists,
    List<HomeFolderEntry>? folders,
    List<SongModel>? videoAudio,
    HomeFilter? activeFilter,
  }) {
    return HomeLoaded(
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      mostPlayed: mostPlayed ?? this.mostPlayed,
      favorites: favorites ?? this.favorites,
      recentlyAdded: recentlyAdded ?? this.recentlyAdded,
      allSongs: allSongs ?? this.allSongs,
      playlists: playlists ?? this.playlists,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      folders: folders ?? this.folders,
      videoAudio: videoAudio ?? this.videoAudio,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [
        recentlyPlayed,
        mostPlayed,
        favorites,
        recentlyAdded,
        allSongs,
        playlists,
        albums,
        artists,
        folders,
        videoAudio,
        activeFilter,
      ];
}

final class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
