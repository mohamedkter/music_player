part of 'settings_bloc.dart';

sealed class SettingsEvent {}

final class SettingsLoadRequested extends SettingsEvent {}

final class SettingsThemeChanged extends SettingsEvent {
  SettingsThemeChanged(this.mode);
  final ThemeMode mode;
}

final class SettingsAccentColorChanged extends SettingsEvent {
  SettingsAccentColorChanged(this.color);
  final Color color;
}

final class SettingsDynamicColorToggled extends SettingsEvent {}

final class SettingsIgnoreShortAudioToggled extends SettingsEvent {}

final class SettingsMinDurationChanged extends SettingsEvent {
  SettingsMinDurationChanged(this.seconds);
  final int seconds;
}

final class SettingsFolderExcluded extends SettingsEvent {
  SettingsFolderExcluded(this.path);
  final String path;
}

final class SettingsFolderIncluded extends SettingsEvent {
  SettingsFolderIncluded(this.path);
  final String path;
}

final class SettingsScanRequested extends SettingsEvent {}
