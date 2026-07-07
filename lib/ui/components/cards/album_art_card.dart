import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Square album artwork card used in grid views (Albums, Artists).
///
/// Shows [coverPath] if available, otherwise a styled placeholder
/// with a music note icon. Displays [title] and [subtitle] below.
///
/// Usage:
/// ```dart
/// AlbumArtCard(
///   title: album.title,
///   subtitle: album.artist,
///   coverPath: album.coverPath,
///   onTap: () => navigateToAlbum(album),
/// )
/// ```
class AlbumArtCard extends StatelessWidget {
  const AlbumArtCard({
    super.key,
    required this.title,
    this.subtitle,
    this.coverPath,
    this.onTap,
    this.size = 160,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final String? coverPath;
  final VoidCallback? onTap;

  /// Width/height of the artwork square.
  final double size;

  /// Optional badge widget shown in top-right (e.g. song count chip).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArtworkSquare(coverPath: coverPath, size: size, badge: badge),
            AppSpacing.vGap(AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTextStyles.labelSm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkSquare extends StatelessWidget {
  const _ArtworkSquare({
    required this.coverPath,
    required this.size,
    this.badge,
  });

  final String? coverPath;
  final double size;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildArtwork(),
          if (badge != null)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: badge!,
            ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    if (coverPath != null && coverPath!.isNotEmpty) {
      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(size: size),
      );
    }
    return _Placeholder(size: size);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.music_note_outlined,
          size: size * 0.35,
          color: AppColors.outline,
        ),
      ),
    );
  }
}
