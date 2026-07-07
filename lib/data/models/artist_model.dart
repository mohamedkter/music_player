import 'package:equatable/equatable.dart';

class ArtistModel extends Equatable {
  const ArtistModel({
    required this.id,
    required this.name,
    required this.numberOfTracks,
    required this.numberOfAlbums,
    this.coverPath,
  });

  final int id;
  final String name;
  final int numberOfTracks;
  final int numberOfAlbums;
  final String? coverPath;

  ArtistModel copyWith({
    int? id,
    String? name,
    int? numberOfTracks,
    int? numberOfAlbums,
    String? coverPath,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      numberOfTracks: numberOfTracks ?? this.numberOfTracks,
      numberOfAlbums: numberOfAlbums ?? this.numberOfAlbums,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  @override
  List<Object?> get props => [id, name, numberOfTracks, numberOfAlbums, coverPath];
}
