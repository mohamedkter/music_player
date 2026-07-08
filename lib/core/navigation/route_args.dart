import 'package:equatable/equatable.dart';
import '../../data/models/album_model.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';

/// Typed arguments for [AppRoutes.categorySongs].
final class CategorySongsArgs extends Equatable {
  const CategorySongsArgs({
    required this.title,
    required this.songs,
  });

  final String title;
  final List<SongModel> songs;

  @override
  List<Object?> get props => [title, songs];
}

/// Typed arguments for [AppRoutes.playlists].
final class PlaylistsArgs extends Equatable {
  const PlaylistsArgs({required this.playlists});

  final List<PlaylistModel> playlists;

  @override
  List<Object?> get props => [playlists];
}

/// Typed arguments for [AppRoutes.albumDetail].
final class AlbumDetailArgs extends Equatable {
  const AlbumDetailArgs({required this.album});

  final AlbumModel album;

  @override
  List<Object?> get props => [album];
}
