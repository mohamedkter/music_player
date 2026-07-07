import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Wraps [SharedPreferences] for all settings persistence.
/// One method per setting — no magic string access outside this class.
class PreferencesDataSource {
  const PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;
  static const _tag = 'PreferencesDataSource';

  // ── Theme ─────────────────────────────────────────────────────────────────
  ThemeMode getThemeMode() {
    final idx = _prefs.getInt(AppConstants.prefThemeMode) ?? 2;
    return ThemeMode.values[idx.clamp(0, 2)];
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _setInt(AppConstants.prefThemeMode, mode.index);

  // ── Accent Color ──────────────────────────────────────────────────────────
  Color getAccentColor() {
    final val = _prefs.getInt(AppConstants.prefAccentColor) ?? 0xFF6240C9;
    return Color(val);
  }

  Future<void> saveAccentColor(Color c) =>
      _setInt(AppConstants.prefAccentColor, c.toARGB32());

  // ── Dynamic Color ─────────────────────────────────────────────────────────
  bool getDynamicColor() =>
      _prefs.getBool(AppConstants.prefDynamicColor) ?? true;

  Future<void> saveDynamicColor(bool v) =>
      _setBool(AppConstants.prefDynamicColor, v);

  // ── Short audio filter ────────────────────────────────────────────────────
  bool getIgnoreShortAudio() =>
      _prefs.getBool(AppConstants.prefIgnoreShortAudio) ?? true;

  Future<void> saveIgnoreShortAudio(bool v) =>
      _setBool(AppConstants.prefIgnoreShortAudio, v);

  int getMinAudioDuration() =>
      _prefs.getInt(AppConstants.prefMinAudioDuration) ??
      AppConstants.minTrackDurationSeconds;

  Future<void> saveMinAudioDuration(int secs) =>
      _setInt(AppConstants.prefMinAudioDuration, secs);

  // ── Excluded folders ──────────────────────────────────────────────────────
  List<String> getExcludedFolders() =>
      _prefs.getStringList(AppConstants.prefExcludedFolders) ?? [];

  Future<void> saveExcludedFolders(List<String> folders) =>
      _setList(AppConstants.prefExcludedFolders, folders);

  // ── Playback ──────────────────────────────────────────────────────────────
  double getPlaybackSpeed() =>
      _prefs.getDouble(AppConstants.prefPlaybackSpeed) ?? 1.0;

  Future<void> savePlaybackSpeed(double s) =>
      _setDouble(AppConstants.prefPlaybackSpeed, s);

  int getRepeatMode() =>
      _prefs.getInt(AppConstants.prefRepeatMode) ?? 0;

  Future<void> saveRepeatMode(int m) =>
      _setInt(AppConstants.prefRepeatMode, m);

  bool getShuffleEnabled() =>
      _prefs.getBool(AppConstants.prefShuffleEnabled) ?? false;

  Future<void> saveShuffleEnabled(bool v) =>
      _setBool(AppConstants.prefShuffleEnabled, v);

  int getLastSongId() =>
      _prefs.getInt(AppConstants.prefLastSongId) ?? -1;

  Future<void> saveLastSongId(int id) =>
      _setInt(AppConstants.prefLastSongId, id);

  int getLastPosition() =>
      _prefs.getInt(AppConstants.prefLastPosition) ?? 0;

  Future<void> saveLastPosition(int ms) =>
      _setInt(AppConstants.prefLastPosition, ms);

  // ── Private typed helpers (no magic strings, no dynamic casts) ────────────
  Future<void> _setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e, st) {
      AppLogger.error('Prefs setInt failed: $key', tag: _tag, error: e, stackTrace: st);
      throw StorageException('Failed to save $key: $e');
    }
  }

  Future<void> _setDouble(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
    } catch (e, st) {
      AppLogger.error('Prefs setDouble failed: $key', tag: _tag, error: e, stackTrace: st);
      throw StorageException('Failed to save $key: $e');
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e, st) {
      AppLogger.error('Prefs setBool failed: $key', tag: _tag, error: e, stackTrace: st);
      throw StorageException('Failed to save $key: $e');
    }
  }

  Future<void> _setList(String key, List<String> value) async {
    try {
      await _prefs.setStringList(key, value);
    } catch (e, st) {
      AppLogger.error('Prefs setList failed: $key', tag: _tag, error: e, stackTrace: st);
      throw StorageException('Failed to save $key: $e');
    }
  }
}
