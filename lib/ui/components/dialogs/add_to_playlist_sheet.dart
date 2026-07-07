import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../data/models/song_model.dart';
import '../../../../data/models/playlist_model.dart';
import '../../../../data/repositories/playlist_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AddToPlaylistSheet extends StatefulWidget {
  const AddToPlaylistSheet({
    super.key,
    required this.song,
  });

  final SongModel song;

  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(song: song),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final _playlistRepository = sl<PlaylistRepository>();

  @override
  Widget build(BuildContext context) {
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
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADD TO PLAYLIST',
                    style: AppTextStyles.headlineSm.copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCreatePlaylistDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 1.5),
                        color: AppColors.gold,
                      ),
                      child: Text(
                        'NEW PLAYLIST',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2, color: AppColors.border),

            // Reactive Playlists List
            Flexible(
              child: StreamBuilder<List<PlaylistModel>>(
                stream: _playlistRepository.watchPlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }

                  final playlists = snapshot.data ?? [];
                  if (playlists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xl,
                      ),
                      child: Center(
                        child: Text(
                          'NO PLAYLISTS YET',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: playlists.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border, width: 1),
                            color: AppColors.surfaceContainerHigh,
                          ),
                          child: const Icon(
                            Icons.playlist_play,
                            color: AppColors.outline,
                          ),
                        ),
                        title: Text(
                          playlist.name.toUpperCase(),
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${playlist.songCount} SONGS',
                          style: AppTextStyles.labelSm,
                        ),
                        onTap: () => _addSongToPlaylist(context, playlist),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        title: Text(
          'CREATE PLAYLIST',
          style: AppTextStyles.headlineSm.copyWith(letterSpacing: 1.0),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'PLAYLIST NAME',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border, width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'CANCEL',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final result = await _playlistRepository.createPlaylist(name);
                result.fold(
                  (_) => _showSnackbar(context, 'FAILED TO CREATE PLAYLIST'),
                  (_) => _showSnackbar(context, 'PLAYLIST CREATED'),
                );
              }
            },
            child: Text(
              'CREATE',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSongToPlaylist(BuildContext context, PlaylistModel playlist) async {
    Navigator.pop(context); // Close sheet
    final result = await _playlistRepository.addSongToPlaylist(playlist.id, widget.song.id);
    result.fold(
      (_) => _showSnackbar(context, 'FAILED TO ADD SONG'),
      (_) => _showSnackbar(context, 'ADDED TO ${playlist.name.toUpperCase()}'),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.border,
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: AppTextStyles.labelMd.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
