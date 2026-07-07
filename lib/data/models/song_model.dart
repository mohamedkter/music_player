import 'package:equatable/equatable.dart';

/// Immutable domain model for a song.
/// No dependency on any framework or database library — pure Dart.
class SongModel extends Equatable {
  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.data,
    required this.duration,
    required this.size,
    required this.dateAdded,
    this.genre,
    this.track,
    this.year,
    this.coverPath,
    this.bitrate,
    this.playCount = 0,
    this.lastPlayed = 0,
    this.isFavorite = false,
  });

  final int id;
  final String title;
  final String artist;
  final String album;

  /// Absolute file path on device.
  final String data;

  /// Duration in milliseconds.
  final int duration;

  /// File size in bytes.
  final int size;

  /// Unix timestamp of when the file was added.
  final int dateAdded;

  final String? genre;
  final int? track;
  final int? year;
  final String? coverPath;
  final int? bitrate;
  final int playCount;
  final int lastPlayed;
  final bool isFavorite;

  // ── Computed helpers ──────────────────────────────────────────────────────

  String get fileExtension => data.split('.').last.toLowerCase();

  String get folderName {
    final slash = data.lastIndexOf('/');
    if (slash < 0) return '';
    return data.substring(0, slash).split('/').last;
  }

  String get folderPath {
    final slash = data.lastIndexOf('/');
    if (slash < 0) return '';
    return data.substring(0, slash);
  }

  Duration get durationObj => Duration(milliseconds: duration);

  // ── copyWith ──────────────────────────────────────────────────────────────

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? data,
    int? duration,
    int? size,
    int? dateAdded,
    String? genre,
    int? track,
    int? year,
    String? coverPath,
    int? bitrate,
    int? playCount,
    int? lastPlayed,
    bool? isFavorite,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      data: data ?? this.data,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      genre: genre ?? this.genre,
      track: track ?? this.track,
      year: year ?? this.year,
      coverPath: coverPath ?? this.coverPath,
      bitrate: bitrate ?? this.bitrate,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id, title, artist, album, data, duration, size,
        dateAdded, genre, track, year, coverPath, bitrate,
        playCount, lastPlayed, isFavorite,
      ];
}
