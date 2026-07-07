part of 'songs_bloc.dart';

sealed class SongsEvent {}

/// Load all songs on screen init.
final class SongsLoadRequested extends SongsEvent {}

/// User changed the search query.
final class SongsSearchChanged extends SongsEvent {
  SongsSearchChanged(this.query);
  final String query;
}

/// User cleared the search bar.
final class SongsSearchCleared extends SongsEvent {}

/// User changed the sort order.
final class SongsSortChanged extends SongsEvent {
  SongsSortChanged(this.sort);
  final SongSortOption sort;
}

/// User toggled favorite on a song.
final class SongFavoriteToggled extends SongsEvent {
  SongFavoriteToggled(this.songId);
  final int songId;
}
