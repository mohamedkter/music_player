import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../core/utils/logger.dart';

import 'package:flutter/foundation.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._songRepository, this._playlistRepository)
      : super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
    on<HomeFilterChanged>(_onFilterChanged);
    on<HomeVideosLoadRequested>(_onLoadVideos);
  }

  final SongRepository _songRepository;
  final PlaylistRepository _playlistRepository;
  static const _tag = 'HomeBloc';

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    final isRefresh = event is HomeRefreshRequested;

    if (state is! HomeLoaded) {
      emit(HomeLoading());
    }

    try {
      // 1. First, load whatever is in the cache (disk or memory)
      final cacheResults = await Future.wait([
        _songRepository.getAllSongs(forceRefresh: isRefresh),
        _playlistRepository.getAllPlaylists(),
      ]);

      final allSongs =
          (cacheResults[0] as dynamic).fold((_) => <SongModel>[], (s) => s)
              as List<SongModel>;
      final playlists =
          (cacheResults[1] as dynamic).fold((_) => <PlaylistModel>[], (s) => s)
              as List<PlaylistModel>;

      if (allSongs.isNotEmpty) {
        final index = await compute(_buildHomeIndex, allSongs);
        emit(_buildLoadedState(allSongs, playlists, index));
      }

      // 2. If it's a cold startup (not a manual refresh), trigger a background check
      // to see if new songs have been added to MediaStore.
      if (!isRefresh) {
        final freshSongsResult = await _songRepository.getAllSongs(forceRefresh: true);
        await freshSongsResult.fold(
          (_) async {},
          (freshSongs) async {
            if (state is HomeLoaded) {
              final currentLoaded = state as HomeLoaded;
              // Only trigger a rebuild if song count or metadata differs
              if (freshSongs.length != allSongs.length ||
                  !_areSongListsIdentical(freshSongs, allSongs)) {
                final index = await compute(_buildHomeIndex, freshSongs);
                emit(_buildLoadedState(freshSongs, currentLoaded.playlists, index));
              }
            }
          },
        );
      }
    } catch (e, st) {
      AppLogger.error('HomeBloc load', tag: _tag, error: e, stackTrace: st);
      if (state is! HomeLoaded) {
        emit(HomeError(e.toString()));
      }
    }
  }

  bool _areSongListsIdentical(List<SongModel> list1, List<SongModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].playCount != list2[i].playCount ||
          list1[i].isFavorite != list2[i].isFavorite) {
        return false;
      }
    }
    return true;
  }

  HomeLoaded _buildLoadedState(
    List<SongModel> songs,
    List<PlaylistModel> playlists,
    _HomeIndexResult index,
  ) {
    // Derive all sub-lists locally (no extra DB round-trips)
    final recentlyPlayed = (List<SongModel>.from(songs)
          ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed)))
        .where((s) => s.lastPlayed > 0)
        .take(12)
        .toList();

    final mostPlayed = (List<SongModel>.from(songs)
          ..sort((a, b) => b.playCount.compareTo(a.playCount)))
        .where((s) => s.playCount > 0)
        .take(12)
        .toList();

    final favorites = songs.where((s) => s.isFavorite).toList();

    final recentlyAdded = (List<SongModel>.from(songs)
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)))
        .take(30)
        .toList();

    return HomeLoaded(
      recentlyPlayed: recentlyPlayed,
      mostPlayed: mostPlayed,
      favorites: favorites,
      recentlyAdded: recentlyAdded,
      allSongs: songs,
      playlists: playlists,
      albums: index.albums,
      artists: index.artists,
      folders: index.folders,
      videoAudio: const [],
      activeFilter: HomeFilter.all,
    );
  }

  void _onFilterChanged(HomeFilterChanged event, Emitter<HomeState> emit) {
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(activeFilter: event.filter));
      // Lazy-load videos only when VIDEOS tab is first selected
      if (event.filter == HomeFilter.videos && current.videoAudio.isEmpty) {
        add(HomeVideosLoadRequested());
      }
    }
  }

  Future<void> _onLoadVideos(
    HomeVideosLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) return;
    final result = await _songRepository.getAllVideos();
    result.fold(
      (_) {}, // silently ignore errors for videos
      (videos) => emit(current.copyWith(videoAudio: videos)),
    );
  }
}

// ── Public data helpers exposed to the view ───────────────────────────────────

class HomeAlbumEntry {
  HomeAlbumEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.songId,
  });
  final int id;
  final String title;
  final String artist;
  final int songId; // for artwork
}

class HomeArtistEntry {
  HomeArtistEntry({required this.name, required this.songId}) : count = 1;
  final String name;
  final int songId;
  int count;
}

class HomeFolderEntry {
  HomeFolderEntry({
    required this.name,
    required this.path,
    required this.songs,
  });
  final String name;
  final String path;
  final List<SongModel> songs;
  int get songCount => songs.length;
}

class _HomeIndexResult {
  _HomeIndexResult({
    required this.albums,
    required this.artists,
    required this.folders,
  });
  final List<HomeAlbumEntry> albums;
  final List<HomeArtistEntry> artists;
  final List<HomeFolderEntry> folders;
}

_HomeIndexResult _buildHomeIndex(List<SongModel> songs) {
  final albumMap = <String, HomeAlbumEntry>{};
  for (final s in songs) {
    if (!albumMap.containsKey(s.album)) {
      albumMap[s.album] = HomeAlbumEntry(
        id: s.id,
        title: s.album,
        artist: s.artist,
        songId: s.id,
      );
    }
  }

  final artistMap = <String, HomeArtistEntry>{};
  for (final s in songs) {
    final key = s.artist;
    if (!artistMap.containsKey(key)) {
      artistMap[key] = HomeArtistEntry(name: s.artist, songId: s.id);
    } else {
      artistMap[key]!.count++;
    }
  }

  final folderMap = <String, List<SongModel>>{};
  for (final song in songs) {
    folderMap.putIfAbsent(song.folderPath, () => []).add(song);
  }
  final folders = folderMap.entries
      .map(
        (e) => HomeFolderEntry(
          name: e.key.split('/').last,
          path: e.key,
          songs: e.value,
        ),
      )
      .toList()
    ..sort((a, b) => b.songCount.compareTo(a.songCount));

  return _HomeIndexResult(
    albums: albumMap.values.toList(),
    artists: artistMap.values.toList(),
    folders: folders,
  );
}
