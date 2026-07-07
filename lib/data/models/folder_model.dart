import 'package:equatable/equatable.dart';
import 'song_model.dart';

class FolderModel extends Equatable {
  const FolderModel({
    required this.path,
    required this.name,
    required this.songs,
  });

  final String path;
  final String name;
  final List<SongModel> songs;

  int get songCount => songs.length;

  @override
  List<Object?> get props => [path, name, songs];
}
