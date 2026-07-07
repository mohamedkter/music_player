import 'package:equatable/equatable.dart';
import 'song_model.dart';

enum PlaylistType { custom, favorites, recentlyPlayed, mostPlayed }

class PlaylistModel extends Equatable {
  const PlaylistModel({
    required this.id,
    required this.name,
    required this.type,
    this.coverPath,
    this.songs = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt,
        updatedAt = updatedAt;

  final int id;
  final String name;
  final PlaylistType type;
  final String? coverPath;
  final List<SongModel> songs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDefault => type != PlaylistType.custom;
  int get songCount => songs.length;

  PlaylistModel copyWith({
    int? id,
    String? name,
    PlaylistType? type,
    String? coverPath,
    List<SongModel>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      coverPath: coverPath ?? this.coverPath,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, type, coverPath, songs, createdAt, updatedAt];
}
