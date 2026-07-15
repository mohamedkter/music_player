import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../ui/components/feedback/app_error_widget.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../player/bloc/player_bloc.dart';
import '../bloc/home_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<HomeBloc>()..add(HomeLoadRequested()),
      child: const _HomeView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root view
// ─────────────────────────────────────────────────────────────────────────────

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          // Only rebuild the entire scaffold when switching between
          // loading/error/loaded states — NOT on every filter change.
          buildWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType ||
              (prev is HomeLoaded && curr is HomeLoaded &&
               prev.allSongs.length != curr.allSongs.length),
          builder: (context, state) => switch (state) {
            HomeInitial() || HomeLoading() => const AppLoadingWidget(),
            HomeError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () =>
                    context.read<HomeBloc>().add(HomeRefreshRequested()),
              ),
            final HomeLoaded s => _HomeContent(state: s),
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main content — CustomScrollView with Category Menu
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<HomeBloc>().add(HomeRefreshRequested()),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Tappable Search Bar — never rebuilds on filter change ───────
          SliverToBoxAdapter(child: _HomeSearchBar()),

          // ── Category Menu — rebuilds only when song data changes ────────
          SliverToBoxAdapter(child: _HomeCategoriesMenu(state: state)),

          // ── Divider ────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: _BrutalistDivider(label: 'ALL MEDIA'),
            ),
          ),

          // ── Filter tabs — rebuilds only when activeFilter changes ───────
          BlocSelector<HomeBloc, HomeState, HomeFilter>(
            selector: (s) => s is HomeLoaded ? s.activeFilter : HomeFilter.all,
            builder: (ctx, activeFilter) => SliverPersistentHeader(
              pinned: true,
              delegate: _FilterTabsDelegate(activeFilter: activeFilter),
            ),
          ),

          // ── Media grid — rebuilds only when filter or data changes ──────
          BlocSelector<HomeBloc, HomeState, HomeLoaded?>(
            selector: (s) => s is HomeLoaded ? s : null,
            builder: (ctx, loaded) => loaded != null
                ? _FilteredMediaSliver(state: loaded)
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable Search Bar — navigates to SearchScreen
// ─────────────────────────────────────────────────────────────────────────────

class _HomeSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
      ),
      child: GestureDetector(
        onTap: () => AppRouter.pushSearch(context),
        // Absorb pointer so TextField inside doesn't get focus (decorative only)
        child: AbsorbPointer(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowNeutral,
                  offset: Offset(3, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.outline,
                  ),
                ),
                Expanded(
                  child: Text(
                    'SEARCH SONGS, ARTISTS, ALBUMS...',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.outline,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.keyboard_alt_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Categories Menu List
// ─────────────────────────────────────────────────────────────────────────────

class _HomeCategoriesMenu extends StatelessWidget {
  const _HomeCategoriesMenu({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final items = <_CategoryItem>[];

    if (state.recentlyPlayed.isNotEmpty) {
      items.add(_CategoryItem(
        title: 'RECENTLY PLAYED',
        subtitle: '${state.recentlyPlayed.length} TRACKS',
        songId: state.recentlyPlayed.first.id,
        onTap: () => AppRouter.pushCategorySongs(
          context,
          title: 'RECENTLY PLAYED',
          songs: state.recentlyPlayed,
        ),
      ));
    }

    if (state.mostPlayed.isNotEmpty) {
      items.add(_CategoryItem(
        title: 'MOST PLAYED',
        subtitle: '${state.mostPlayed.length} TRACKS',
        songId: state.mostPlayed.first.id,
        onTap: () => AppRouter.pushCategorySongs(
          context,
          title: 'MOST PLAYED',
          songs: state.mostPlayed,
        ),
      ));
    }

    if (state.favorites.isNotEmpty) {
      items.add(_CategoryItem(
        title: 'FAVORITES',
        subtitle: '${state.favorites.length} TRACKS',
        songId: state.favorites.first.id,
        onTap: () => AppRouter.pushCategorySongs(
          context,
          title: 'FAVORITE SONGS',
          songs: state.favorites,
        ),
      ));
    }

    if (state.playlists.isNotEmpty) {
      final firstPlaylistWithSongs = state.playlists.firstWhere(
        (p) => p.songs.isNotEmpty,
        orElse: () => state.playlists.first,
      );
      items.add(_CategoryItem(
        title: 'PLAYLISTS',
        subtitle: '${state.playlists.length} PLAYLISTS',
        songId: firstPlaylistWithSongs.songs.isNotEmpty
            ? firstPlaylistWithSongs.songs.first.id
            : null,
        onTap: () => AppRouter.pushPlaylists(
          context,
          playlists: state.playlists,
        ),
      ));
    }


    if (state.recentlyAdded.isNotEmpty) {
      items.add(_CategoryItem(
        title: 'RECENTLY ADDED',
        subtitle: '${state.recentlyAdded.length} TRACKS',
        songId: state.recentlyAdded.first.id,
        onTap: () => AppRouter.pushCategorySongs(
          context,
          title: 'RECENTLY ADDED',
          songs: state.recentlyAdded,
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return _CategoryMenuCard(
            title: item.title,
            subtitle: item.subtitle,
            songId: item.songId,
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}

class _CategoryItem {
  _CategoryItem({
    required this.title,
    required this.subtitle,
    this.songId,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final int? songId;
  final VoidCallback onTap;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Menu Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryMenuCard extends StatelessWidget {
  const _CategoryMenuCard({
    required this.title,
    required this.subtitle,
    this.songId,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int? songId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 124,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          color: AppColors.surfaceContainerHigh,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowNeutral,
              offset: Offset(3, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Artwork
            if (songId != null)
              oaq.QueryArtworkWidget(
                id: songId!,
                type: oaq.ArtworkType.AUDIO,
                artworkWidth: double.infinity,
                artworkHeight: double.infinity,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                keepOldArtwork: true,
                nullArtworkWidget: const _CategoryPlaceholder(),
                errorBuilder: (_, __, ___) => const _CategoryPlaceholder(),
              )
            else
              const _CategoryPlaceholder(),

            // Dark gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSm.copyWith(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Icon(
        Icons.music_note,
        color: AppColors.outline,
        size: 32,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brutalist divider
// ─────────────────────────────────────────────────────────────────────────────

class _BrutalistDivider extends StatelessWidget {
  const _BrutalistDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: AppColors.border,
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
        ),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned filter tabs delegate
// ─────────────────────────────────────────────────────────────────────────────

class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  const _FilterTabsDelegate({required this.activeFilter});
  final HomeFilter activeFilter;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  bool shouldRebuild(_FilterTabsDelegate old) =>
      old.activeFilter != activeFilter;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        children: HomeFilter.values.map((filter) {
          final isActive = filter == activeFilter;
          return GestureDetector(
            onTap: () =>
                context.read<HomeBloc>().add(HomeFilterChanged(filter)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: AppColors.shadowPrimary,
                          offset: Offset(2, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                filter.label,
                style: AppTextStyles.labelSm.copyWith(
                  color: isActive ? Colors.white : AppColors.onSurface,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtered media sliver
// ─────────────────────────────────────────────────────────────────────────────

class _FilteredMediaSliver extends StatelessWidget {
  const _FilteredMediaSliver({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    return switch (state.activeFilter) {
      HomeFilter.all => _AllMediaGrid(state: state),
      HomeFilter.songs => _SongsGrid(songs: state.allSongs),
      HomeFilter.albums => _AlbumsGrid(albums: state.albums, allSongs: state.allSongs),
      HomeFilter.artists => _ArtistsGrid(artists: state.artists, allSongs: state.allSongs),
      HomeFilter.playlists => _PlaylistsGrid(playlists: state.playlists),
      HomeFilter.folders => _FoldersGrid(folders: state.folders),
      HomeFilter.videos => _VideosGrid(songs: state.videoAudio),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALL filter — compact mixed grid
// ─────────────────────────────────────────────────────────────────────────────

class _AllMediaGrid extends StatelessWidget {
  const _AllMediaGrid({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    // Combine a compact listing: songs first, then albums, then artists
    final songs = state.allSongs.take(10).toList();
    return SliverList.separated(
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (ctx, i) {
        final song = songs[i];
        return _MediaListTile(
          songId: song.id,
          title: song.title,
          subtitle: song.artist,
          type: 'SONG',
          onTap: () => ctx.read<PlayerBloc>().add(
                PlayerSongRequested(song: song, queue: state.allSongs),
              ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Songs grid
// ─────────────────────────────────────────────────────────────────────────────

class _SongsGrid extends StatefulWidget {
  const _SongsGrid({required this.songs});
  final List<SongModel> songs;

  @override
  State<_SongsGrid> createState() => _SongsGridState();
}

class _SongsGridState extends State<_SongsGrid> {
  static const _pageSize = 50;
  int _loadedCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    if (widget.songs.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyFilterState(label: 'NO SONGS'));
    }

    final visible = widget.songs.take(_loadedCount).toList();
    final hasMore = _loadedCount < widget.songs.length;

    return SliverList.separated(
      itemCount: visible.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (ctx, i) {
        // Load more trigger
        if (i == visible.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _loadedCount += _pageSize);
          });
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final song = visible[i];
        return RepaintBoundary(
          child: _MediaListTile(
            songId: song.id,
            title: song.title,
            subtitle: '${song.artist} · ${song.album}',
            type: song.fileExtension.toUpperCase(),
            onTap: () => ctx.read<PlayerBloc>().add(
                  PlayerSongRequested(song: song, queue: widget.songs),
                ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Albums grid (2-col)
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumsGrid extends StatelessWidget {
  const _AlbumsGrid({required this.albums, required this.allSongs});
  final List<HomeAlbumEntry> albums;
  final List<SongModel> allSongs;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyFilterState(label: 'NO ALBUMS'));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: albums.length,
        itemBuilder: (ctx, i) {
          final album = albums[i];
          return _AlbumGridCard(album: album, allSongs: allSongs);
        },
      ),
    );
  }
}

class _AlbumGridCard extends StatelessWidget {
  const _AlbumGridCard({required this.album, required this.allSongs});
  final HomeAlbumEntry album;
  final List<SongModel> allSongs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final albumSongs = allSongs
            .where((s) => s.album == album.title && s.artist == album.artist)
            .toList();
        AppRouter.pushCategorySongs(
          context,
          title: album.title,
          songs: albumSongs.isNotEmpty ? albumSongs : allSongs,
        );
      },
      child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 2),
        color: AppColors.surfaceContainerLowest,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowNeutral,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork
          Expanded(
            child: oaq.QueryArtworkWidget(
              id: album.songId,
              type: oaq.ArtworkType.AUDIO,
              artworkWidth: double.infinity,
              artworkHeight: double.infinity,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.zero,
              keepOldArtwork: true,
              nullArtworkWidget: Container(
                color: AppColors.surfaceContainerHigh,
                child: const Icon(
                  Icons.album,
                  color: AppColors.outline,
                  size: 40,
                ),
              ),
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Icon(
                  Icons.album,
                  color: AppColors.outline,
                  size: 40,
                ),
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album.artist,
                  style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ), // Container
    ); // GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Folders grid
// ─────────────────────────────────────────────────────────────────────────────

class _FoldersGrid extends StatelessWidget {
  const _FoldersGrid({required this.folders});
  final List<HomeFolderEntry> folders;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyFilterState(label: 'NO FOLDERS'));
    }
    return SliverList.separated(
      itemCount: folders.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (ctx, i) {
        final folder = folders[i];
        return RepaintBoundary(
          child: _FolderListTile(folder: folder),
        );
      },
    );
  }
}

class _FolderListTile extends StatelessWidget {
  const _FolderListTile({required this.folder});
  final HomeFolderEntry folder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppRouter.pushCategorySongs(
          context,
          title: folder.name.toUpperCase(),
          songs: folder.songs,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Folder icon box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowNeutral,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name.toUpperCase(),
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    folder.path,
                    style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${folder.songCount} TRACKS',
                    style: AppTextStyles.labelSm,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Artists grid
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistsGrid extends StatelessWidget {
  const _ArtistsGrid({required this.artists, required this.allSongs});
  final List<HomeArtistEntry> artists;
  final List<SongModel> allSongs;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyFilterState(label: 'NO ARTISTS'));
    }
    return SliverList.separated(
      itemCount: artists.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (ctx, i) {
        final artist = artists[i];
        return RepaintBoundary(
          child: _ArtistListTile(artist: artist, allSongs: allSongs),
        );
      },
    );
  }
}

class _ArtistListTile extends StatelessWidget {
  const _ArtistListTile({required this.artist, required this.allSongs});
  final HomeArtistEntry artist;
  final List<SongModel> allSongs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final artistSongs = allSongs
            .where((s) => s.artist == artist.name)
            .toList();
        AppRouter.pushCategorySongs(
          context,
          title: artist.name,
          songs: artistSongs,
        );
      },
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          // Circle artwork
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              color: AppColors.surfaceContainerHigh,
            ),
            clipBehavior: Clip.antiAlias,
            child: oaq.QueryArtworkWidget(
              id: artist.songId,
              type: oaq.ArtworkType.AUDIO,
              artworkWidth: 50,
              artworkHeight: 50,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.circular(25),
              keepOldArtwork: true,
              nullArtworkWidget: const Icon(
                Icons.person,
                color: AppColors.outline,
                size: 26,
              ),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                color: AppColors.outline,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${artist.count} TRACKS',
                  style: AppTextStyles.labelSm,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.outline,
          ),
        ],
      ),
    ), // Container
    ); // GestureDetector
  }
}
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistsGrid extends StatelessWidget {
  const _PlaylistsGrid({required this.playlists});
  final List<PlaylistModel> playlists;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyFilterState(label: 'NO PLAYLISTS'));
    }
    return SliverList.separated(
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (ctx, i) {
        final pl = playlists[i];
        return _PlaylistListTile(playlist: pl);
      },
    );
  }
}

class _PlaylistListTile extends StatelessWidget {
  const _PlaylistListTile({required this.playlist});
  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    final firstSongId =
        playlist.songs.isNotEmpty ? playlist.songs.first.id : null;

    return GestureDetector(
      onTap: () => AppRouter.pushCategorySongs(
        context,
        title: playlist.name,
        songs: playlist.songs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Artwork square
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                color: AppColors.surfaceContainerHigh,
              ),
              clipBehavior: Clip.antiAlias,
              child: firstSongId != null
                  ? oaq.QueryArtworkWidget(
                      id: firstSongId,
                      type: oaq.ArtworkType.AUDIO,
                      artworkWidth: 54,
                      artworkHeight: 54,
                      artworkFit: BoxFit.cover,
                      artworkBorder: BorderRadius.zero,
                      keepOldArtwork: true,
                      nullArtworkWidget: const Icon(
                        Icons.playlist_play,
                        color: AppColors.outline,
                        size: 28,
                      ),
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.playlist_play,
                        color: AppColors.outline,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.playlist_play,
                      color: AppColors.outline,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name.toUpperCase(),
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.songCount} TRACKS',
                    style: AppTextStyles.labelSm,
                  ),
                ],
              ),
            ),
            // Gold accent badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: AppColors.gold,
              child: const Icon(Icons.play_arrow, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Videos grid
// ─────────────────────────────────────────────────────────────────────────────

class _VideosGrid extends StatelessWidget {
  const _VideosGrid({required this.songs});
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyFilterState(label: 'NO VIDEO AUDIO FOUND'),
      );
    }
    return SliverList.separated(
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (ctx, i) {
        final song = songs[i];
        return RepaintBoundary(
          child: _MediaListTile(
            songId: song.id,
            title: song.title,
            subtitle: song.artist,
            type: song.fileExtension.toUpperCase(),
            typeColor: AppColors.primary,
            icon: Icons.videocam_outlined,
            onTap: () => ctx.read<PlayerBloc>().add(
                  PlayerSongRequested(song: song, queue: songs),
                ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic media list tile
// ─────────────────────────────────────────────────────────────────────────────

class _MediaListTile extends StatelessWidget {
  const _MediaListTile({
    required this.songId,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onTap,
    this.typeColor,
    this.icon,
  });

  final int songId;
  final String title;
  final String subtitle;
  final String type;
  final VoidCallback onTap;
  final Color? typeColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Artwork
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                color: AppColors.surfaceContainerHigh,
              ),
              clipBehavior: Clip.antiAlias,
              child: oaq.QueryArtworkWidget(
                id: songId,
                type: oaq.ArtworkType.AUDIO,
                artworkWidth: 50,
                artworkHeight: 50,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                keepOldArtwork: true,
                nullArtworkWidget: Icon(
                  icon ?? Icons.music_note,
                  color: AppColors.outline,
                  size: 22,
                ),
                errorBuilder: (_, __, ___) => Icon(
                  icon ?? Icons.music_note,
                  color: AppColors.outline,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              color: typeColor ?? AppColors.surfaceContainerHigh,
              child: Text(
                type,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 9,
                  color: typeColor != null ? Colors.white : AppColors.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state for filters
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: AppColors.outline,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(letterSpacing: 2.0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlists grid