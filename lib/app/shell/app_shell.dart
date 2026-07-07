import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../data/models/album_model.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/album_repository.dart';
import '../../data/repositories/artist_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../features/albums/bloc/albums_bloc.dart';
import '../../features/albums/view/albums_screen.dart';
import '../../features/home/bloc/home_bloc.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/player/bloc/player_bloc.dart';
import '../../features/player/view/now_playing_screen.dart';
import '../../features/search/bloc/search_bloc.dart';
import '../../features/settings/bloc/settings_bloc.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/songs/bloc/songs_bloc.dart';
import '../../features/songs/view/songs_screen.dart';
import '../../core/bloc/theme/theme_bloc.dart';
import '../../ui/components/navigation/app_bottom_nav.dart';
import '../../ui/components/player/mini_player.dart';

/// Root shell that:
/// 1. Provides all feature BLoCs via [MultiBlocProvider]
/// 2. Manages bottom tab navigation with [IndexedStack] (preserves state)
/// 3. Shows [MiniPlayer] above nav when a song is active
/// 4. Wires [PlayerBloc] into [MiniPlayer] actions
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _buildProviders(),
      child: Builder(
        builder: (ctx) => Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              HomeScreen(),
              SongsScreen(),
              AlbumsScreen(),
              _PlaylistsPlaceholder(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Mini Player ──────────────────────────────────────────────
              BlocBuilder<PlayerBloc, PlayerState>(
                builder: (_, playerState) {
                  if (!playerState.hasSong) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => _openNowPlaying(ctx),
                    child: MiniPlayer(
                      state: _PlayerStateAdapter(playerState),
                      onPlayPause: () => ctx
                          .read<PlayerBloc>()
                          .add(PlayerTogglePlayPause()),
                      onSkipNext: () =>
                          ctx.read<PlayerBloc>().add(PlayerSkipToNext()),
                      onTap: () => _openNowPlaying(ctx),
                    ),
                  );
                },
              ),
              // ── Bottom Nav ───────────────────────────────────────────────
              AppBottomNav(
                currentIndex: _currentIndex,
                items: AppNavItems.all,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => BlocProvider.value(
          value: context.read<PlayerBloc>(),
          child: const NowPlayingScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  List<BlocProvider> _buildProviders() {
    final songRepo = sl<SongRepository>();
    final settingsRepo = sl<SettingsRepository>();
    final themeBloc = sl<ThemeBloc>();

    return [
      BlocProvider<PlayerBloc>(
        create: (_) => PlayerBloc(songRepo),
        lazy: false,
      ),
      BlocProvider<HomeBloc>(
        create: (_) => HomeBloc(songRepo),
      ),
      BlocProvider<SongsBloc>(
        create: (_) => SongsBloc(songRepo),
      ),
      BlocProvider<AlbumsBloc>(
        create: (_) => AlbumsBloc(_AlbumRepoStub()),
      ),
      BlocProvider<SearchBloc>(
        create: (_) => SearchBloc(
          songRepository: songRepo,
          albumRepository: _AlbumRepoStub(),
          artistRepository: _ArtistRepoStub(),
        ),
      ),
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc(
          settingsRepository: settingsRepo,
          songRepository: songRepo,
          themeBloc: themeBloc,
        ),
      ),
    ];
  }
}

// ── MiniPlayerState adapter ───────────────────────────────────────────────────

/// Adapts [PlayerState] to the [MiniPlayerState] interface
/// without coupling MiniPlayer directly to PlayerBloc.
class _PlayerStateAdapter implements MiniPlayerState {
  const _PlayerStateAdapter(this._state);

  final PlayerState _state;

  @override
  String get songTitle => _state.currentSong?.title ?? '';

  @override
  String get artistName => _state.currentSong?.artist ?? '';

  @override
  String? get coverPath => _state.currentSong?.coverPath;

  @override
  bool get isPlaying => _state.isPlaying;

  @override
  Duration get position => _state.position;

  @override
  Duration get duration => _state.duration;
}

// ── Placeholder screens ───────────────────────────────────────────────────────

class _PlaylistsPlaceholder extends StatelessWidget {
  const _PlaylistsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: Center(
        child: Text(
          'Playlists\n(coming soon)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

// ── Stub repositories (until album/artist repos are fully wired to DI) ───────

class _AlbumRepoStub implements AlbumRepository {
  @override
  Future<Either<Failure, List<AlbumModel>>> getAllAlbums() async =>
      right([]);

  @override
  Future<Either<Failure, AlbumModel>> getAlbumById(int id) async =>
      left(const NotFoundFailure());

  @override
  Future<Either<Failure, List<AlbumModel>>> searchAlbums(String q) async =>
      right([]);
}

class _ArtistRepoStub implements ArtistRepository {
  @override
  Future<Either<Failure, List<ArtistModel>>> getAllArtists() async =>
      right([]);

  @override
  Future<Either<Failure, ArtistModel>> getArtistById(int id) async =>
      left(const NotFoundFailure());

  @override
  Future<Either<Failure, List<ArtistModel>>> searchArtists(String q) async =>
      right([]);
}
