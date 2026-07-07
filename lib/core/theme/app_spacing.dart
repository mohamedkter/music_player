import 'package:flutter/material.dart';

/// Spacing tokens — strict 4px base unit system.
/// Use these constants everywhere instead of raw numbers.
abstract final class AppSpacing {
  static const double unit = 4.0;
  static const double xs = 4.0;   // unit × 1
  static const double sm = 8.0;   // unit × 2
  static const double md = 16.0;  // unit × 4
  static const double lg = 24.0;  // unit × 6
  static const double xl = 48.0;  // unit × 12

  /// Horizontal gutter inside containers.
  static const double gutter = 24.0;

  /// Horizontal margin on mobile screens.
  static const double marginMobile = 16.0;

  /// Horizontal margin on desktop/tablet.
  static const double marginDesktop = 64.0;

  // ── Edge Insets shortcuts ─────────────────────────────────────────────────
  static const EdgeInsets pagePaddingMobile = EdgeInsets.symmetric(
    horizontal: marginMobile,
    vertical: md,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );

  // ── SizedBox shortcuts ────────────────────────────────────────────────────
  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget gapSm = SizedBox(height: sm, width: sm);
  static const Widget gapMd = SizedBox(height: md, width: md);
  static const Widget gapLg = SizedBox(height: lg, width: lg);
  static const Widget gapXl = SizedBox(height: xl, width: xl);

  static Widget hGap(double value) => SizedBox(width: value);
  static Widget vGap(double value) => SizedBox(height: value);
}
