part of 'theme_bloc.dart';

sealed class ThemeEvent {}

/// Change the app theme mode.
final class ThemeModeChanged extends ThemeEvent {
  ThemeModeChanged(this.mode);
  final ThemeMode mode;
}

/// Toggle between light and dark.
final class ThemeToggled extends ThemeEvent {}
