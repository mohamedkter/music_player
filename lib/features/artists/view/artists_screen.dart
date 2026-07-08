import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/artist_model.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_error_widget.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/inputs/app_search_bar.dart';
import '../bloc/artists_bloc.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ctx.read<ArtistsBloc>()..add(ArtistsLoadRequested()),
      child: const _ArtistsView(),
    );
  }
}

class _ArtistsView extends StatelessWidget {
  const _ArtistsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARTISTS',
            style: AppTextStyles.headlineMd.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vGap(AppSpacing.md),
          AppSearchBar(
            hintText: 'Search artists...',
            onChanged: (q) =>
                context.read<ArtistsBloc>().add(ArtistsSearchChanged(q)),
            onClear: () =>
                context.read<ArtistsBloc>().add(ArtistsSearchCleared()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtistsBloc, ArtistsState>(
      builder: (context, state) => switch (state) {
        ArtistsInitial() => const SizedBox.shrink(),
        ArtistsLoading() =>
          const AppLoadingWidget(message: 'Loading artists...'),
        ArtistsError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                context.read<ArtistsBloc>().add(ArtistsLoadRequested()),
          ),
        ArtistsLoaded(:final artists, :final allArtists, :final searchQuery) =>
          artists.isEmpty
              ? AppEmptyState(
                  icon: searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.person_off_outlined,
                  title: searchQuery.isNotEmpty
                      ? 'No results for "$searchQuery"'
                      : 'No Artists Found',
                )
              : _ArtistsList(artists: artists, totalCount: allArtists.length),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Artists list
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistsList extends StatelessWidget {
  const _ArtistsList({required this.artists, required this.totalCount});

  final List<ArtistModel> artists;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              '${artists.length} of $totalCount',
              style: AppTextStyles.labelMd,
            ),
          ),
        ),
        SliverList.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return _ArtistTile(artist: artist);
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist});

  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AppRouter.pushArtistDetail(context, artist: artist),
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
                color: AppColors.surfaceContainerHigh,
              ),
              clipBehavior: Clip.antiAlias,
              child: oaq.QueryArtworkWidget(
                id: artist.id,
                type: oaq.ArtworkType.ARTIST,
                artworkWidth: 52,
                artworkHeight: 52,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.circular(26),
                keepOldArtwork: true,
                nullArtworkWidget: const Icon(
                  Icons.person,
                  color: AppColors.outline,
                  size: 28,
                ),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: AppColors.outline,
                  size: 28,
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
                  const SizedBox(height: 2),
                  Text(
                    '${artist.numberOfTracks} TRACKS'
                    '${artist.numberOfAlbums > 0 ? ' · ${artist.numberOfAlbums} ALBUMS' : ''}',
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
