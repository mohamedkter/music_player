import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/album_model.dart';
import '../../../ui/components/cards/album_art_card.dart';
import '../../../ui/components/chips/app_chip.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_error_widget.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/inputs/app_search_bar.dart';
import '../bloc/albums_bloc.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<AlbumsBloc>()..add(AlbumsLoadRequested()),
      child: const _AlbumsView(),
    );
  }
}

class _AlbumsView extends StatelessWidget {
  const _AlbumsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            const Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Albums', style: AppTextStyles.headlineMd),
          AppSpacing.vGap(AppSpacing.sm),
          AppSearchBar(
            hintText: 'Search albums...',
            onChanged: (q) =>
                context.read<AlbumsBloc>().add(AlbumsSearchChanged(q)),
            onClear: () =>
                context.read<AlbumsBloc>().add(AlbumsSearchCleared()),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlbumsBloc, AlbumsState>(
      builder: (context, state) => switch (state) {
        AlbumsInitial() => const SizedBox.shrink(),
        AlbumsLoading() => const AppLoadingWidget(message: 'Loading albums...'),
        AlbumsError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                context.read<AlbumsBloc>().add(AlbumsLoadRequested()),
          ),
        AlbumsLoaded(:final albums, :final allAlbums, :final searchQuery) =>
          albums.isEmpty
              ? AppEmptyState(
                  icon: Icons.album_outlined,
                  title: searchQuery.isNotEmpty
                      ? 'No results for "$searchQuery"'
                      : 'No Albums Found',
                )
              : _AlbumsGrid(albums: albums, totalCount: allAlbums.length),
      },
    );
  }
}

class _AlbumsGrid extends StatelessWidget {
  const _AlbumsGrid({required this.albums, required this.totalCount});

  final List<dynamic> albums;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final crossCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    final itemWidth =
        (MediaQuery.of(context).size.width - AppSpacing.md * 2 -
                AppSpacing.sm * (crossCount - 1)) /
            crossCount;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: itemWidth / (itemWidth + 52),
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) {
              final album = albums[i];
              return AlbumArtCard(
                title: album.title,
                subtitle: album.artist,
                coverPath: album.coverPath,
                size: itemWidth,
                badge: AppChip(
                  label: '${album.numberOfSongs}',
                  variant: AppChipVariant.dark,
                ),
                onTap: () {
                  final albumModel = album as AlbumModel;
                  AppRouter.pushAlbumDetail(context, album: albumModel);
                },
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
