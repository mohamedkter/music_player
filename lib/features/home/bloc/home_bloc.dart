import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../core/utils/logger.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._songRepository, this._playlistRepository)
      : super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
    on<HomeFilterChanged>(_onFilterChanged);
  }

  final SongRepository _songRepository;
  final PlaylistRepository _playlistRepository;
  static const _tag = 'HomeBloc';

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoading());

    // On Android, MediaStore may not be ready immediately after permission is
    // granted on first launch. We retry up to 5 times with a growing delay
    // so the user never has to pull-to-refresh manually.
    const maxRetries = 5;
    const retryDelay = Duration(milliseconds: 1500);

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // Run all queries concurrently for faster load
        final results = await Future.wait([
          _songRepository.getRecentlyPlayed(limit: 12),
          _songRepository.getMostPlayed(limit: 12),
          _songRepository.getFavorites(),
          _songRepository.getRecentlyAdded(limit: 30),
          _songRepository.getAllSongs(),
          _playlistRepository.getAllPlaylists(),
        ]);

        final recentlyPlayed =
            (results[0] as dynamic).fold((_) => <SongModel>[], (s) => s)
                as List<SongModel>;
        final mostPlayed =
            (results[1] as dynamic).fold((_) => <SongModel>[], (s) => s)
                as List<SongModel>;
        final favorites =
            (results[2] as dynamic).fold((_) => <SongModel>[], (s) => s)
                as List<SongModel>;
        final recentlyAdded =
            (results[3] as dynamic).fold((_) => <SongModel>[], (s) => s)
                as List<SongModel>;
        final allSongs =
            (results[4] as dynamic).fold((_) => <SongModel>[], (s) => s)
                as List<SongModel>;
        final playlists =
            (results[5] as dynamic).fold((_) => <PlaylistModel>[], (s) => s)
                as List<PlaylistModel>;

        // If songs came back empty and we still have retries left, wait and
        // try again — MediaStore may not have synced yet after permission grant.
        if (allSongs.isEmpty && attempt < maxRetries) {
          AppLogger.info(
            'Songs empty on attempt ${attempt + 1}/$maxRetries — retrying in ${retryDelay.inMilliseconds}ms',
            tag: _tag,
          );
          await Future<void>.delayed(retryDelay);
          continue;
        }

        // Derive albums & artists from songs (group locally — no extra permission needed)
        final albumMap = <String, HomeAlbumEntry>{};
        for (final s in allSongs) {
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
        for (final s in allSongs) {
          final key = s.artist;
          if (!artistMap.containsKey(key)) {
            artistMap[key] = HomeArtistEntry(name: s.artist, songId: s.id);
          } else {
            artistMap[key]!.count++;
          }
        }

        // Video audio — songs whose fileExtension is a video format
        final videoAudio = allSongs
            .where(
                (s) => _videoExtensions.contains(s.fileExtension.toLowerCase()))
            .toList();

        // Folders
        final folderMap = <String, List<SongModel>>{};
        for (final song in allSongs) {
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

        emit(HomeLoaded(
          recentlyPlayed: recentlyPlayed,
          mostPlayed: mostPlayed,
          favorites: favorites,
          recentlyAdded: recentlyAdded,
          allSongs: allSongs,
          playlists: playlists,
          albums: albumMap.values.toList(),
          artists: artistMap.values.toList(),
          folders: folders,
          videoAudio: videoAudio,
          activeFilter: HomeFilter.all,
        ));
        return; // Success — exit the loop
      } catch (e, st) {
        if (attempt == maxRetries) {
          AppLogger.error('HomeBloc load', tag: _tag, error: e, stackTrace: st);
          emit(HomeError(e.toString()));
          return;
        }
        // Transient error — wait and retry
        AppLogger.warning(
          'HomeBloc load error on attempt ${attempt + 1}: $e — retrying',
          tag: _tag,
        );
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  void _onFilterChanged(HomeFilterChanged event, Emitter<HomeState> emit) {
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(activeFilter: event.filter));
    }
  }

  static const _videoExtensions = {
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp', 'm4v',
  };
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
