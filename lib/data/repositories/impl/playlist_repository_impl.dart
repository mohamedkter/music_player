import 'dart:convert';
import 'package:rxdart/rxdart.dart'; // We can check if rxdart is imported or use standard StreamController
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../playlist_repository.dart';
import '../song_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(this._prefs, this._songRepository) {
    _loadPlaylists();
  }

  final SharedPreferences _prefs;
  final SongRepository _songRepository;
  
  static const _prefPlaylistsKey = 'pref_playlists_json_list';

  // Reactive stream of playlists
  final _playlistsSubject = BehaviorSubject<List<PlaylistModel>>.seeded([]);

  void _loadPlaylists() async {
    try {
      final jsonList = _prefs.getStringList(_prefPlaylistsKey) ?? [];
      final List<PlaylistModel> loaded = [];

      // Fetch all songs to match by ID
      final songsResult = await _songRepository.getAllSongs();
      final allSongs = songsResult.fold((_) => <SongModel>[], (songs) => songs);

      for (final jsonStr in jsonList) {
        try {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          final id = map['id'] as int;
          final name = map['name'] as String;
          final typeIndex = map['type'] as int;
          final type = PlaylistType.values[typeIndex];
          final coverPath = map['coverPath'] as String?;
          final songIds = List<int>.from(map['songIds'] as List<dynamic>);
          
          final createdAt = map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : null;
          final updatedAt = map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null;

          // Map song IDs to actual SongModels present on the device
          final List<SongModel> songs = [];
          for (final songId in songIds) {
            final song = allSongs.cast<SongModel?>().firstWhere(
                  (s) => s?.id == songId,
                  orElse: () => null,
                );
            if (song != null) {
              songs.add(song);
            }
          }

          loaded.add(PlaylistModel(
            id: id,
            name: name,
            type: type,
            coverPath: coverPath,
            songs: songs,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ));
        } catch (_) {
          // Skip corrupt item
        }
      }

      _playlistsSubject.add(loaded);
    } catch (_) {
      _playlistsSubject.add([]);
    }
  }

  Future<void> _savePlaylists(List<PlaylistModel> playlists) async {
    final List<String> jsonList = [];
    for (final p in playlists) {
      final map = {
        'id': p.id,
        'name': p.name,
        'type': p.type.index,
        'coverPath': p.coverPath,
        'songIds': p.songs.map((s) => s.id).toList(),
        'createdAt': p.createdAt?.toIso8601String(),
        'updatedAt': p.updatedAt?.toIso8601String(),
      };
      jsonList.add(json.encode(map));
    }
    await _prefs.setStringList(_prefPlaylistsKey, jsonList);
    _playlistsSubject.add(playlists);
  }

  @override
  Future<Either<Failure, List<PlaylistModel>>> getAllPlaylists() async {
    return right(_playlistsSubject.value);
  }

  @override
  Future<Either<Failure, PlaylistModel>> getPlaylistById(int id) async {
    final list = _playlistsSubject.value;
    final item = list.cast<PlaylistModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (item != null) {
      return right(item);
    }
    return left(const NotFoundFailure());
  }

  @override
  Future<Either<Failure, PlaylistModel>> createPlaylist(String name) async {
    try {
      final list = List<PlaylistModel>.from(_playlistsSubject.value);
      final id = DateTime.now().millisecondsSinceEpoch;
      final newPlaylist = PlaylistModel(
        id: id,
        name: name,
        type: PlaylistType.custom,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      list.add(newPlaylist);
      await _savePlaylists(list);
      return right(newPlaylist);
    } catch (e) {
      return left(const StorageFailure());
    }
  }

  @override
  Future<Either<Failure, PlaylistModel>> renamePlaylist(int id, String name) async {
    try {
      final list = List<PlaylistModel>.from(_playlistsSubject.value);
      final idx = list.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        final updated = list[idx].copyWith(
          name: name,
          updatedAt: DateTime.now(),
        );
        list[idx] = updated;
        await _savePlaylists(list);
        return right(updated);
      }
      return left(const NotFoundFailure());
    } catch (e) {
      return left(const StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylist(int id) async {
    try {
      final list = List<PlaylistModel>.from(_playlistsSubject.value);
      list.removeWhere((p) => p.id == id);
      await _savePlaylists(list);
      return right(null);
    } catch (e) {
      return left(const StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addSongToPlaylist(int playlistId, int songId) async {
    try {
      final list = List<PlaylistModel>.from(_playlistsSubject.value);
      final idx = list.indexWhere((p) => p.id == playlistId);
      if (idx >= 0) {
        final playlist = list[idx];
        if (playlist.songs.any((s) => s.id == songId)) {
          return right(null); // Already in playlist
        }

        // Fetch actual song model
        final songsResult = await _songRepository.getAllSongs();
        final song = songsResult.fold(
          (_) => null,
          (songs) => songs.cast<SongModel?>().firstWhere(
                (s) => s?.id == songId,
                orElse: () => null,
              ),
        );
        if (song == null) {
          return left(const NotFoundFailure());
        }

        final updatedSongs = List<SongModel>.from(playlist.songs)..add(song);
        final updated = playlist.copyWith(
          songs: updatedSongs,
          updatedAt: DateTime.now(),
        );
        list[idx] = updated;
        await _savePlaylists(list);
        return right(null);
      }
      return left(const NotFoundFailure());
    } catch (e) {
      return left(const StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      final list = List<PlaylistModel>.from(_playlistsSubject.value);
      final idx = list.indexWhere((p) => p.id == playlistId);
      if (idx >= 0) {
        final playlist = list[idx];
        final updatedSongs = List<SongModel>.from(playlist.songs)
          ..removeWhere((s) => s.id == songId);
        final updated = playlist.copyWith(
          songs: updatedSongs,
          updatedAt: DateTime.now(),
        );
        list[idx] = updated;
        await _savePlaylists(list);
        return right(null);
      }
      return left(const NotFoundFailure());
    } catch (e) {
      return left(const StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> reorderPlaylist(
    int playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final list = List<PlaylistModel>.from(_playlistsSubject.value);
      final idx = list.indexWhere((p) => p.id == playlistId);
      if (idx >= 0) {
        final playlist = list[idx];
        final updatedSongs = List<SongModel>.from(playlist.songs);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = updatedSongs.removeAt(oldIndex);
        updatedSongs.insert(newIndex, item);

        final updated = playlist.copyWith(
          songs: updatedSongs,
          updatedAt: DateTime.now(),
        );
        list[idx] = updated;
        await _savePlaylists(list);
        return right(null);
      }
      return left(const NotFoundFailure());
    } catch (e) {
      return left(const StorageFailure());
    }
  }

  @override
  Stream<List<PlaylistModel>> watchPlaylists() => _playlistsSubject.stream;
}
