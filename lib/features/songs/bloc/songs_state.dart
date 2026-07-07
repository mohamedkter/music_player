part of 'songs_bloc.dart';

enum SongSortOption {
  titleAsc,
  titleDesc,
  artistAsc,
  albumAsc,
  dateNewest,
  dateOldest,
  durationLongest,
  durationShortest,
}

sealed class SongsState extends Equatable {
  const SongsState();
  @override
  List<Object?> get props => [];
}

final class SongsInitial extends SongsState {}

final class SongsLoading extends SongsState {}

final class SongsLoaded extends SongsState {
  const SongsLoaded({
    required this.songs,
    required this.allSongs,
    this.searchQuery = '',
    this.sort = SongSortOption.titleAsc,
  });

  final List<SongModel> songs;       // Filtered + sorted — shown in UI
  final List<SongModel> allSongs;    // Full unfiltered list
  final String searchQuery;
  final SongSortOption sort;

  SongsLoaded copyWith({
    List<SongModel>? songs,
    List<SongModel>? allSongs,
    String? searchQuery,
    SongSortOption? sort,
  }) {
    return SongsLoaded(
      songs: songs ?? this.songs,
      allSongs: allSongs ?? this.allSongs,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [songs, allSongs, searchQuery, sort];
}

final class SongsError extends SongsState {
  const SongsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
