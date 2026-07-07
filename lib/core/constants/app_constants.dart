/// Central place for all application-wide constants.
/// Follows Single Responsibility Principle — only constants live here.
abstract final class AppConstants {
  // ── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'Music Player';
  static const String appVersion = '1.0.0';

  // ── Audio ─────────────────────────────────────────────────────────────────
  /// Minimum track duration in seconds to be included in the library.
  static const int minTrackDurationSeconds = 30;

  /// Supported audio file extensions.
  static const List<String> supportedAudioFormats = [
    'mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a', 'opus',
  ];

  // ── Playback Speeds ───────────────────────────────────────────────────────
  static const List<double> playbackSpeeds = [
    0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0,
  ];
  static const double defaultPlaybackSpeed = 1.0;

  // ── Sleep Timer Presets (minutes) ─────────────────────────────────────────
  static const List<int> sleepTimerPresets = [5, 10, 15, 30, 45, 60, 120];

  // ── Limits ────────────────────────────────────────────────────────────────
  static const int recentlyPlayedLimit = 50;
  static const int mostPlayedLimit = 20;
  static const int recentlyAddedLimit = 30;
  static const int searchHistoryLimit = 10;

  // ── Notification Channel ─────────────────────────────────────────────────
  static const String audioNotificationChannelId =
      'com.example.music_player.audio';
  static const String audioNotificationChannelName = 'Music Playback';

  // ── Shared Preferences Keys ───────────────────────────────────────────────
  static const String prefThemeMode = 'theme_mode';
  static const String prefAccentColor = 'accent_color';
  static const String prefDynamicColor = 'dynamic_color';
  static const String prefIgnoreShortAudio = 'ignore_short_audio';
  static const String prefMinAudioDuration = 'min_audio_duration';
  static const String prefExcludedFolders = 'excluded_folders';
  static const String prefLastSongId = 'last_song_id';
  static const String prefLastPosition = 'last_position';
  static const String prefShuffleEnabled = 'shuffle_enabled';
  static const String prefRepeatMode = 'repeat_mode';
  static const String prefPlaybackSpeed = 'playback_speed';
  static const String prefEqPreset = 'eq_preset';
  static const String prefSelectedDancer = 'selected_dancer';
  static const List<String> dancerAnimations = [
    'assets/animations/Astronaut and music.json',
    'assets/animations/Happy Spaceman.json',
    'assets/animations/A fitness cow.json',
    'assets/animations/Pepe Sticker Music.json',
  ];
}
