import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/utils/duration_formatter.dart';
import '../bloc/player_bloc.dart';
import 'widgets/speed_bottom_sheet.dart';
import 'widgets/sleep_timer_bottom_sheet.dart';
import '../../../../ui/components/dialogs/add_to_playlist_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (!state.hasSong) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Text('Nothing playing',
                  style: AppTextStyles.headlineSm),
            ),
          );
        }
        return _NowPlayingView(state: state);
      },
    );
  }
}

class _NowPlayingView extends StatelessWidget {
  const _NowPlayingView({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              _Header(state: state),
              // ── Album Art ──────────────────────────────────────────────
              _AlbumArt(state: state),
              // ── Song Info ──────────────────────────────────────────────
              _SongInfo(state: state),
              // ── Progress Bar ───────────────────────────────────────────
              _ProgressBar(state: state),
              // ── Controls ───────────────────────────────────────────────
              _Controls(state: state),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Spacer(),
          // More options
          GestureDetector(
            onTap: () => _showMoreOptions(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 2),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OptionTile(
                icon: Icons.speed,
                label: 'PLAYBACK SPEED',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SpeedBottomSheet(
                      currentSpeed: state.speed,
                      onSelected: (s) => playerBloc.add(PlayerSpeedChanged(s)),
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.bedtime_outlined,
                label: 'SLEEP TIMER',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: playerBloc,
                      child: const SleepTimerBottomSheet(),
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.queue_music,
                label: 'QUEUE',
                onTap: () {
                  Navigator.pop(context);
                  AppRouter.pushQueue(context);
                },
              ),
              _OptionTile(
                icon: Icons.playlist_add,
                label: 'ADD TO PLAYLIST',
                onTap: () {
                  Navigator.pop(context);
                  if (state.currentSong != null) {
                    AddToPlaylistSheet.show(context, state.currentSong!);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.onSurface),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurface,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Album Art ─────────────────────────────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final songId = state.currentSong?.id;
    final size = MediaQuery.of(context).size.width - (AppSpacing.md * 2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Container(
        width: double.infinity,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          color: AppColors.surfaceContainerHigh,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Album artwork
            songId != null
                ? oaq.QueryArtworkWidget(
                    id: songId,
                    type: oaq.ArtworkType.AUDIO,
                    artworkWidth: double.infinity,
                    artworkHeight: double.infinity,
                    artworkFit: BoxFit.cover,
                    artworkBorder: BorderRadius.zero,
                    keepOldArtwork: true,
                    nullArtworkWidget: _ArtworkPlaceholder(size: size),
                    errorBuilder: (_, __, ___) => _ArtworkPlaceholder(size: size),
                  )
                : _ArtworkPlaceholder(size: size),

            // Dancing character overlay (bottom left)
            Positioned(
              bottom: -10,
              left: -10,
              child: IgnorePointer(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: Lottie.asset(
                    state.selectedDancer,
                    animate: state.isPlaying,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Dancer selection button (bottom right)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showDancerSelectionSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowNeutral,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.accessibility_new,
                        size: 14,
                        color: AppColors.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DANCER',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDancerSelectionSheet(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocBuilder<PlayerBloc, PlayerState>(
          bloc: playerBloc,
          builder: (context, state) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Bar
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'SELECT DANCING CHARACTER',
                        style: AppTextStyles.headlineSm.copyWith(
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Divider(height: 1, thickness: 2, color: AppColors.border),

                    // Dancer Grid
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: AppConstants.dancerAnimations.map((path) {
                          final isSelected = state.selectedDancer == path;
                          final name = _getDancerName(path);

                          return GestureDetector(
                            onTap: () {
                              playerBloc.add(PlayerDancerChanged(path));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surfaceContainerLow,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? const [
                                        BoxShadow(
                                          color: AppColors.shadowPrimary,
                                          offset: Offset(3, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Lottie.asset(
                                      path,
                                      animate: true,
                                      repeat: true,
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    alignment: Alignment.center,
                                    child: Text(
                                      name,
                                      style: AppTextStyles.labelSm.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDancerName(String path) {
    if (path.contains('cow')) return 'FITNESS COW';
    if (path.contains('Astronaut')) return 'ASTRONAUT';
    if (path.contains('Happy')) return 'HAPPY SPACEMAN';
    if (path.contains('Pepe')) return 'DANCING PEPE';
    return 'DANCER';
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: size * 0.3,
          color: AppColors.outline,
        ),
      ),
    );
  }
}

// ── Song Info ─────────────────────────────────────────────────────────────────

class _SongInfo extends StatelessWidget {
  const _SongInfo({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final song = state.currentSong;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NOW SPINNING label
                Text(
                  'NOW SPINNING',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                // Song title — large brutalist
                _MarqueeText(
                  text: (song?.title ?? '—').toUpperCase(),
                  style: AppTextStyles.headlineLg.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Artist name
                Text(
                  song?.artist ?? '',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Metadata chips
                _MetadataChips(state: state),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Brutalist Favorite Button
          GestureDetector(
            onTap: () => context.read<PlayerBloc>().add(PlayerFavoriteToggled()),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                color: (song?.isFavorite ?? false)
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowNeutral,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
              child: Icon(
                (song?.isFavorite ?? false) ? Icons.favorite : Icons.favorite_border,
                color: (song?.isFavorite ?? false) ? Colors.white : AppColors.onSurface,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataChips extends StatelessWidget {
  const _MetadataChips({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final song = state.currentSong;
    final chips = <String>[];

    if (song?.album != null && song!.album.isNotEmpty) {
      chips.add(song.album);
    }
    if (song?.year != null) {
      chips.add('${song!.year}');
    }
    final ext = song?.fileExtension.toUpperCase() ?? '';
    if (ext.isNotEmpty) {
      chips.add(ext);
    }
    if (state.speed != 1.0) {
      chips.add('${state.speed}×');
    }
    if (state.isSleepTimerActive && state.sleepTimerRemaining != null) {
      chips.add('SLEEP: ${DurationFormatter.format(state.sleepTimerRemaining!)}');
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.map((c) => _Chip(label: c)).toList(),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 10,
          color: AppColors.onSurface,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final total = state.duration.inMilliseconds.toDouble();
    final pos = state.position.inMilliseconds
        .toDouble()
        .clamp(0.0, total > 0 ? total : 1.0);
    final progress = total > 0 ? pos / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Column(
        children: [
          // Custom brutalist progress bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: constraints.maxWidth * progress,
                      color: AppColors.primary,
                    ),
                  ],
                );
              },
            ),
          ),
          // Seekbar (invisible, overlapping)
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.15),
                trackHeight: 0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 0),
              ),
              child: Slider(
                value: total > 0 ? pos / total : 0,
                onChanged: (v) {
                  final seek = Duration(
                    milliseconds: (v * total).round(),
                  );
                  context.read<PlayerBloc>().add(PlayerSeekRequested(seek));
                },
              ),
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DurationFormatter.format(state.position),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DurationFormatter.format(state.duration),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlayerBloc>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle on the far left
          _BrutalistButton(
            icon: Icons.shuffle,
            isActive: state.shuffleEnabled,
            onTap: () => bloc.add(PlayerShuffleToggled()),
          ),
          // Previous
          _BrutalistButton(
            icon: Icons.skip_previous,
            onTap: () => bloc.add(PlayerSkipToPrevious()),
          ),
          // Play / Pause — large brutalist square
          GestureDetector(
            onTap: () => bloc.add(PlayerTogglePlayPause()),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowNeutral,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
            ),
          ),
          // Next
          _BrutalistButton(
            icon: Icons.skip_next,
            onTap: () => bloc.add(PlayerSkipToNext()),
          ),
          // Repeat on the far right
          _BrutalistButton(
            icon: switch (state.repeatMode) {
              RepeatMode.off => Icons.repeat,
              RepeatMode.all => Icons.repeat,
              RepeatMode.one => Icons.repeat_one,
            },
            isActive: state.repeatMode != RepeatMode.off,
            onTap: () => bloc.add(PlayerRepeatToggled()),
          ),
        ],
      ),
    );
  }
}

class _BrutalistButton extends StatelessWidget {
  const _BrutalistButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          color: isActive ? AppColors.primary : AppColors.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowNeutral,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? Colors.white : AppColors.onSurface,
        ),
      ),
    );
  }
}

// ── Marquee Text ──────────────────────────────────────────────────────────────

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!mounted || !_scrollController.hasClients) return;
    
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    if (maxScrollExtent > 0) {
      while (mounted && _scrollController.hasClients) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted || !_scrollController.hasClients) break;
        
        await _scrollController.animateTo(
          maxScrollExtent,
          duration: Duration(milliseconds: (maxScrollExtent * 30).toInt() + 1500),
          curve: Curves.linear,
        );
        
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted || !_scrollController.hasClients) break;
        
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}




