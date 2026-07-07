part of 'settings_bloc.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFF6240C9),
    this.dynamicColorEnabled = true,
    this.ignoreShortAudio = true,
    this.minAudioDuration = 30,
    this.excludedFolders = const [],
    this.isScanning = false,
    this.lastScanCount,
  });

  final ThemeMode themeMode;
  final Color accentColor;
  final bool dynamicColorEnabled;
  final bool ignoreShortAudio;
  final int minAudioDuration;
  final List<String> excludedFolders;
  final bool isScanning;
  final int? lastScanCount;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? dynamicColorEnabled,
    bool? ignoreShortAudio,
    int? minAudioDuration,
    List<String>? excludedFolders,
    bool? isScanning,
    int? lastScanCount,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      dynamicColorEnabled: dynamicColorEnabled ?? this.dynamicColorEnabled,
      ignoreShortAudio: ignoreShortAudio ?? this.ignoreShortAudio,
      minAudioDuration: minAudioDuration ?? this.minAudioDuration,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      isScanning: isScanning ?? this.isScanning,
      lastScanCount: lastScanCount ?? this.lastScanCount,
    );
  }

  @override
  List<Object?> get props => [
        themeMode, accentColor, dynamicColorEnabled,
        ignoreShortAudio, minAudioDuration, excludedFolders,
        isScanning, lastScanCount,
      ];
}
