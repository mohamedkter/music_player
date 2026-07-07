import 'package:equatable/equatable.dart';

class AlbumModel extends Equatable {
  const AlbumModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.numberOfSongs,
    this.year,
    this.coverPath,
  });

  final int id;
  final String title;
  final String artist;
  final int numberOfSongs;
  final int? year;
  final String? coverPath;

  AlbumModel copyWith({
    int? id,
    String? title,
    String? artist,
    int? numberOfSongs,
    int? year,
    String? coverPath,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      numberOfSongs: numberOfSongs ?? this.numberOfSongs,
      year: year ?? this.year,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  @override
  List<Object?> get props => [id, title, artist, numberOfSongs, year, coverPath];
}
