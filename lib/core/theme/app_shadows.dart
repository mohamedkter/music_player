import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shadow tokens following the brutalist "hard shadow" principle.
///
/// No blur — a 4px offset solid shadow gives a "lifted card" feel.
/// On press, the element shifts 2px down/right to "meet" the shadow.
abstract final class AppShadows {
  /// Primary purple hard shadow — for primary interactive elements.
  static const List<BoxShadow> hardPrimary = [
    BoxShadow(
      color: AppColors.shadowPrimary,
      offset: Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  /// Neutral dark hard shadow — for cards and secondary containers.
  static const List<BoxShadow> hardNeutral = [
    BoxShadow(
      color: AppColors.shadowNeutral,
      offset: Offset(4, 4),
      blurRadius: 0,
    ),
  ];

  /// Pressed / active inset — element shifts to "meet" the shadow.
  static const List<BoxShadow> hardPressed = [
    BoxShadow(
      color: AppColors.shadowPrimary,
      offset: Offset(2, 2),
      blurRadius: 0,
    ),
  ];

  /// No shadow (reset state).
  static const List<BoxShadow> none = [];
}
