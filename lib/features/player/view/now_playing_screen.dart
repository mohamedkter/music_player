import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../ui/components/buttons/app_icon_button.dart';
import '../bloc/player_bloc.dart';
import 'queue_screen.dart';
import 'widgets/speed_bottom_sheet.dart';
import 'widgets/sleep_timer_bottom_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (!state.hasSong) {
          return const Scaffold(
            body: Center(child: Text('Nothing playing')),
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Dynamic background ─────────────────────────────────────────
          _DynamicBackground(coverPath: state.currentSong?.coverPath),
          // ── Content ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight + 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Expanded(child: _AlbumArt(state: state)),
                        AppSpacing.vGap(AppSpacing.lg),
                        _SongInfo(state: state),
                        AppSpacing.vGap(AppSpacing.md),
                        _ProgressBar(state: state),
                        AppSpacing.vGap(AppSpacing.md),
                        _Controls(state: state),
                        AppSpacing.vGap(AppSpacing.lg),
                        _ToolBar(state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
        onPressed: () => Navigator.pop(context),
        color: Colors.white,
      ),
      title: Text(
        'Now Playing',
        style: AppTextStyles.labelMd.copyWith(color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<_MoreOption>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppColors.surfaceContainerLowest,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.border, width: 2),
          ),
          onSelected: (opt) => _onMoreOption(context, opt),
          itemBuilder: (_) => const [
            PopupMenuItem(value: _MoreOption.speed, child: Text('Playback Speed')),
            PopupMenuItem(value: _MoreOption.sleep, child: Text('Sleep Timer')),
            PopupMenuItem(value: _MoreOption.queue, child: Text('Queue')),
            PopupMenuItem(value: _MoreOption.album, child: Text('Go to Album')),
            PopupMenuItem(value: _MoreOption.artist, child: Text('Go to Artist')),
            PopupMenuItem(value: _MoreOption.addToPlaylist, child: Text('Add to Playlist')),
          ],
        ),
      ],
    );
  }

  void _onMoreOption(BuildContext context, _MoreOption opt) {
    switch (opt) {
      case _MoreOption.speed:
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => SpeedBottomSheet(
            currentSpeed: state.speed,
            onSelected: (s) =>
                context.read<PlayerBloc>().add(PlayerSpeedChanged(s)),
          ),
        );
      case _MoreOption.sleep:
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => const SleepTimerBottomSheet(),
        );
      case _MoreOption.queue:
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const QueueScreen()),
        );
      case _MoreOption.album:
      case _MoreOption.artist:
      case _MoreOption.addToPlaylist:
        // TODO: implement navigation
        break;
    }
  }
}

enum _MoreOption { speed, sleep, queue, album, artist, addToPlaylist }

// ── Dynamic gradient background ───────────────────────────────────────────────

class _DynamicBackground extends StatelessWidget {
  const _DynamicBackground({this.coverPath});

  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    // Fallback color when no artwork
    const baseColor = Color(0xFF1A0A3C);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor,
            Colors.black,
          ],
        ),
      ),
    );
  }
}

// ── Album Art with rotation animation ─────────────────────────────────────────

class _AlbumArt extends StatefulWidget {
  const _AlbumArt({required this.state});

  final PlayerState state;

  @override
  State<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<_AlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.state.isPlaying) _rotCtrl.repeat();
  }

  @override
  void didUpdateWidget(_AlbumArt old) {
    super.didUpdateWidget(old);
    if (widget.state.isPlaying && !_rotCtrl.isAnimating) {
      _rotCtrl.repeat();
    } else if (!widget.state.isPlaying && _rotCtrl.isAnimating) {
      _rotCtrl.stop();
    }
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _rotCtrl,
        child: _buildArt(),
      ),
    );
  }

  Widget _buildArt() {
    final cover = widget.state.currentSong?.coverPath;
    final size = MediaQuery.of(context).size.width * 0.72;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: cover != null && cover.isNotEmpty
          ? Image.file(File(cover), fit: BoxFit.cover)
          : Container(
              color: AppColors.surfaceContainerHigh,
              child: Icon(
                Icons.music_note,
                size: size * 0.4,
                color: AppColors.primary,
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.currentSong?.title ?? '—',
                style: AppTextStyles.headlineSm.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.vGap(AppSpacing.xs),
              Text(
                '${state.currentSong?.artist ?? ''}'
                ' · ${state.currentSong?.album ?? ''}',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white60,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AppSpacing.hGap(AppSpacing.md),
        GestureDetector(
          onTap: () =>
              context.read<PlayerBloc>().add(PlayerFavoriteToggled()),
          child: Icon(
            (state.currentSong?.isFavorite ?? false)
                ? Icons.favorite
                : Icons.favorite_border,
            color: (state.currentSong?.isFavorite ?? false)
                ? AppColors.error
                : Colors.white60,
            size: 28,
          ),
        ),
      ],
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

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            overlayColor: Colors.white24,
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DurationFormatter.format(state.position),
                style: AppTextStyles.labelSm.copyWith(color: Colors.white60),
              ),
              Text(
                DurationFormatter.format(state.duration),
                style: AppTextStyles.labelSm.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        AppIconButton(
          icon: Icons.shuffle,
          isActive: state.shuffleEnabled,
          activeColor: AppColors.inversePrimary,
          onPressed: () => bloc.add(PlayerShuffleToggled()),
        ),
        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
          onPressed: () => bloc.add(PlayerSkipToPrevious()),
        ),
        // Play / Pause — large button
        GestureDetector(
          onTap: () => bloc.add(PlayerTogglePlayPause()),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: AppColors.primary,
                  ),
          ),
        ),
        // Next
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
          onPressed: () => bloc.add(PlayerSkipToNext()),
        ),
        // Repeat
        AppIconButton(
          icon: switch (state.repeatMode) {
            RepeatMode.off => Icons.repeat,
            RepeatMode.all => Icons.repeat,
            RepeatMode.one => Icons.repeat_one,
          },
          isActive: state.repeatMode != RepeatMode.off,
          activeColor: AppColors.inversePrimary,
          onPressed: () => bloc.add(PlayerRepeatToggled()),
        ),
      ],
    );
  }
}

// ── Tool Bar ──────────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  const _ToolBar({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ToolButton(
          icon: Icons.queue_music,
          label: 'Queue',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const QueueScreen()),
          ),
        ),
        _ToolButton(
          icon: Icons.lyrics_outlined,
          label: 'Lyrics',
          onTap: () {}, // TODO
        ),
        _ToolButton(
          icon: Icons.speed,
          label: '${state.speed}x',
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => SpeedBottomSheet(
              currentSpeed: state.speed,
              onSelected: (s) =>
                  context.read<PlayerBloc>().add(PlayerSpeedChanged(s)),
            ),
          ),
        ),
        _ToolButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white60, size: 22),
          AppSpacing.vGap(AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
