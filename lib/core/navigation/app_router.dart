import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/album_model.dart';
import '../../data/models/artist_model.dart';
import '../../features/albums/view/album_detail_screen.dart';
import '../../features/albums/view/albums_screen.dart';
import '../../features/artists/view/artist_detail_screen.dart';

import '../../features/folders/view/folders_screen.dart';
import '../../features/home/view/category_songs_screen.dart';
import '../../features/albums/bloc/albums_bloc.dart';
import '../../features/folders/bloc/folders_bloc.dart';
import '../../features/player/bloc/player_bloc.dart';
import '../../features/player/view/now_playing_screen.dart';
import '../../features/player/view/queue_screen.dart';
import '../../features/search/bloc/search_bloc.dart';
import '../../features/search/view/search_screen.dart';
import '../../features/transfer/view/transfer_screen.dart';
import '../utils/logger.dart';
import 'app_routes.dart';
import 'route_args.dart';

/// Central routing service for the app.
///
/// Responsibilities:
/// - Generate [Route] objects from route names and arguments
/// - Own all transition animations
/// - Provide a programmatic API ([AppRouter.push], etc.) so screens
///   never import each other directly
///
/// Register with [MaterialApp.onGenerateRoute]:
/// ```dart
/// MaterialApp(
///   onGenerateRoute: AppRouter.onGenerateRoute,
/// )
/// ```
abstract final class AppRouter {
  AppRouter._();

  // ── Route factory ──────────────────────────────────────────────────────────

  /// Called by [Navigator] / [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    AppLogger.debug('Navigating to: ${settings.name}', tag: 'Router');

    return switch (settings.name) {
      AppRoutes.categorySongs => _buildCategorySongsRoute(settings),
      AppRoutes.playlists => _buildPlaylistsRoute(settings),
      AppRoutes.search => _buildSearchRoute(settings),
      AppRoutes.transfer => _buildTransferRoute(settings),
      _ => _buildNotFoundRoute(settings),
    };  }

  // ── Programmatic navigation helpers ───────────────────────────────────────

  /// Push [AppRoutes.nowPlaying].
  /// The [PlayerBloc] must already be in scope above the current context.
  static Future<void> pushNowPlaying(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.nowPlaying),
        pageBuilder: (_, __, ___) => BlocProvider.value(
          value: playerBloc,
          child: const NowPlayingScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// Push [AppRoutes.queue].
  /// The [PlayerBloc] must already be in scope above the current context.
  static Future<void> pushQueue(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.queue),
        builder: (_) => BlocProvider.value(
          value: playerBloc,
          child: const QueueScreen(),
        ),
      ),
    );
  }

  /// Push [AppRoutes.categorySongs].
  static Future<void> pushCategorySongs(
    BuildContext context, {
    required String title,
    required List<dynamic> songs,
  }) {
    final playerBloc = context.read<PlayerBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.categorySongs),
        builder: (_) => BlocProvider.value(
          value: playerBloc,
          child: CategorySongsScreen(title: title, songs: songs.cast()),
        ),
      ),
    );
  }

  /// Push [AppRoutes.playlists].
  static Future<void> pushPlaylists(
    BuildContext context, {
    required List<dynamic> playlists,
  }) {
    final playerBloc = context.read<PlayerBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.playlists),
        builder: (_) => BlocProvider.value(
          value: playerBloc,
          child: PlaylistsListScreen(playlists: playlists.cast()),
        ),
      ),
    );
  }

  /// Push [AppRoutes.search].
  /// Forwards [SearchBloc] and [PlayerBloc] from the current context.
  static Future<void> pushSearch(BuildContext context) {
    final searchBloc = context.read<SearchBloc>();
    final playerBloc = context.read<PlayerBloc>();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.search),
        pageBuilder: (_, __, ___) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: searchBloc),
            BlocProvider.value(value: playerBloc),
          ],
          child: const SearchScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Push [AppRoutes.albums].
  static Future<void> pushAlbums(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    final albumsBloc = context.read<AlbumsBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.albums),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: playerBloc),
            BlocProvider.value(value: albumsBloc),
          ],
          child: const AlbumsScreen(),
        ),
      ),
    );
  }

  /// Push [AppRoutes.folders].
  static Future<void> pushFolders(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();
    final foldersBloc = context.read<FoldersBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.folders),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: playerBloc),
            BlocProvider.value(value: foldersBloc),
          ],
          child: const FoldersScreen(),
        ),
      ),
    );
  }

  /// Push [AppRoutes.albumDetail].
  static Future<void> pushAlbumDetail(
    BuildContext context, {
    required AlbumModel album,
  }) {
    // Capture PlayerBloc before leaving current context
    final playerBloc = context.read<PlayerBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.albumDetail),
        builder: (_) => BlocProvider.value(
          value: playerBloc,
          child: AlbumDetailScreen(album: album),
        ),
      ),
    );
  }

  /// Push [AppRoutes.artistDetail].
  static Future<void> pushArtistDetail(
    BuildContext context, {
    required ArtistModel artist,
    PlayerBloc? playerBloc,
  }) {
    final bloc = playerBloc ?? context.read<PlayerBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.artistDetail),
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ArtistDetailScreen(artist: artist),
        ),
      ),
    );
  }

  /// Push [AppRoutes.transfer] — the share/receive music screen.
  static Future<void> pushTransfer(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.transfer),
        pageBuilder: (_, __, ___) => const TransferScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ── Route builders ─────────────────────────────────────────────────────────

  static Route<void> _buildCategorySongsRoute(RouteSettings settings) {
    final args = settings.arguments as CategorySongsArgs?;
    assert(args != null, 'CategorySongsScreen requires CategorySongsArgs');

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => CategorySongsScreen(
        title: args!.title,
        songs: args.songs,
      ),
    );
  }

  static Route<void> _buildPlaylistsRoute(RouteSettings settings) {
    final args = settings.arguments as PlaylistsArgs?;
    assert(args != null, 'PlaylistsListScreen requires PlaylistsArgs');

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => PlaylistsListScreen(playlists: args!.playlists),
    );
  }

  static Route<void> _buildSearchRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const SearchScreen(),
    );
  }

  static Route<void> _buildTransferRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const TransferScreen(),
    );
  }



  static Route<void> _buildNotFoundRoute(RouteSettings settings) {
    AppLogger.error('Unknown route: ${settings.name}', tag: 'Router');
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _NotFoundScreen(routeName: settings.name ?? 'unknown'),
    );
  }
}

// ── 404 screen ────────────────────────────────────────────────────────────────

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'No route defined for "$routeName"',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
