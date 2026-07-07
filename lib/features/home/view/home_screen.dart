import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../ui/components/cards/album_art_card.dart';
import '../../../ui/components/feedback/app_error_widget.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../../player/bloc/player_bloc.dart';
import '../bloc/home_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ctx.read<HomeBloc>()..add(HomeLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => switch (state) {
            HomeInitial() => const SizedBox.shrink(),
            HomeLoading() => const AppLoadingWidget(),
            HomeError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () =>
                    context.read<HomeBloc>().add(HomeRefreshRequested()),
              ),
            HomeLoaded() => _HomeContent(state: state as HomeLoaded),
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning ☀️'
        : hour < 17
            ? 'Good Afternoon 🎵'
            : 'Good Evening 🌙';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<HomeBloc>().add(HomeRefreshRequested()),
      child: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            title: Text(greeting, style: AppTextStyles.headlineSm),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: navigate to SearchScreen
                },
              ),
            ],
          ),

          // ── Recently Played ──────────────────────────────────────────────
          if (state.recentlyPlayed.isNotEmpty) ...[
            _SectionHeader(title: 'Recently Played'),
            _HorizontalSongList(songs: state.recentlyPlayed),
          ],

          // ── Most Played ──────────────────────────────────────────────────
          if (state.mostPlayed.isNotEmpty) ...[
            _SectionHeader(title: 'Most Played 🔥'),
            _HorizontalSongList(songs: state.mostPlayed),
          ],

          // ── Favorites ────────────────────────────────────────────────────
          if (state.favorites.isNotEmpty) ...[
            _SectionHeader(title: 'Favorites ❤️'),
            SliverToBoxAdapter(
              child: Column(
                children: state.favorites
                    .take(5)
                    .map(
                      (song) => SongListItem(
                        title: song.title,
                        artist: song.artist,
                        durationMs: song.duration,
                        coverPath: song.coverPath,
                        isFavorite: true,
                        onTap: () {},
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          // ── Recently Added ───────────────────────────────────────────────
          if (state.recentlyAdded.isNotEmpty) ...[
            _SectionHeader(title: 'Recently Added'),
            _HorizontalAlbumList(songs: state.recentlyAdded),
          ],

          // ── Empty ────────────────────────────────────────────────────────
          if (state.recentlyPlayed.isEmpty &&
              state.mostPlayed.isEmpty &&
              state.favorites.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.library_music_outlined,
                title: 'Your Library is Empty',
                message: 'Go to Settings → Scan Music to get started.',
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.headlineSm),
            GestureDetector(
              onTap: () {}, // TODO: navigate to full list
              child: Text(
                'See all',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalSongList extends StatelessWidget {
  const _HorizontalSongList({required this.songs});

  final List<dynamic> songs;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: songs.length,
          separatorBuilder: (_, __) => AppSpacing.hGap(AppSpacing.sm),
          itemBuilder: (_, i) {
            final song = songs[i];
            return AlbumArtCard(
              title: song.title,
              subtitle: song.artist,
              coverPath: song.coverPath,
              size: 140,
              onTap: () {
                context.read<PlayerBloc>().add(
                  PlayerSongRequested(song: song, queue: songs.cast()),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HorizontalAlbumList extends StatelessWidget {
  const _HorizontalAlbumList({required this.songs});

  final List<dynamic> songs;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: songs.length,
          separatorBuilder: (_, __) => AppSpacing.hGap(AppSpacing.sm),
          itemBuilder: (_, i) {
            final song = songs[i];
            return AlbumArtCard(
              title: song.album,
              subtitle: song.artist,
              coverPath: song.coverPath,
              size: 130,
              onTap: () {
                context.read<PlayerBloc>().add(
                  PlayerSongRequested(song: song, queue: songs.cast()),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
