import 'package:flutter/material.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../../datasources/preferences_datasource.dart';
import '../settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final PreferencesDataSource _prefs;
  static const _tag = 'SettingsRepository';

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() =>
      _wrap(() => _prefs.getThemeMode());

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) =>
      _wrapAsync(() => _prefs.saveThemeMode(mode));

  @override
  Future<Either<Failure, Color>> getAccentColor() =>
      _wrap(() => _prefs.getAccentColor());

  @override
  Future<Either<Failure, void>> saveAccentColor(Color color) =>
      _wrapAsync(() => _prefs.saveAccentColor(color));

  @override
  Future<Either<Failure, bool>> getDynamicColorEnabled() =>
      _wrap(() => _prefs.getDynamicColor());

  @override
  Future<Either<Failure, void>> saveDynamicColorEnabled(bool value) =>
      _wrapAsync(() => _prefs.saveDynamicColor(value));

  @override
  Future<Either<Failure, bool>> getIgnoreShortAudio() =>
      _wrap(() => _prefs.getIgnoreShortAudio());

  @override
  Future<Either<Failure, void>> saveIgnoreShortAudio(bool value) =>
      _wrapAsync(() => _prefs.saveIgnoreShortAudio(value));

  @override
  Future<Either<Failure, int>> getMinAudioDuration() =>
      _wrap(() => _prefs.getMinAudioDuration());

  @override
  Future<Either<Failure, void>> saveMinAudioDuration(int seconds) =>
      _wrapAsync(() => _prefs.saveMinAudioDuration(seconds));

  @override
  Future<Either<Failure, List<String>>> getExcludedFolders() =>
      _wrap(() => _prefs.getExcludedFolders());

  @override
  Future<Either<Failure, void>> saveExcludedFolders(List<String> folders) =>
      _wrapAsync(() => _prefs.saveExcludedFolders(folders));

  @override
  Future<Either<Failure, double>> getPlaybackSpeed() =>
      _wrap(() => _prefs.getPlaybackSpeed());

  @override
  Future<Either<Failure, void>> savePlaybackSpeed(double speed) =>
      _wrapAsync(() => _prefs.savePlaybackSpeed(speed));

  @override
  Future<Either<Failure, int>> getRepeatMode() =>
      _wrap(() => _prefs.getRepeatMode());

  @override
  Future<Either<Failure, void>> saveRepeatMode(int mode) =>
      _wrapAsync(() => _prefs.saveRepeatMode(mode));

  @override
  Future<Either<Failure, bool>> getShuffleEnabled() =>
      _wrap(() => _prefs.getShuffleEnabled());

  @override
  Future<Either<Failure, void>> saveShuffleEnabled(bool value) =>
      _wrapAsync(() => _prefs.saveShuffleEnabled(value));

  @override
  Future<Either<Failure, int>> getLastSongId() =>
      _wrap(() => _prefs.getLastSongId());

  @override
  Future<Either<Failure, void>> saveLastSongId(int id) =>
      _wrapAsync(() => _prefs.saveLastSongId(id));

  @override
  Future<Either<Failure, int>> getLastPosition() =>
      _wrap(() => _prefs.getLastPosition());

  @override
  Future<Either<Failure, void>> saveLastPosition(int ms) =>
      _wrapAsync(() => _prefs.saveLastPosition(ms));

  // ── Error wrapping helpers ────────────────────────────────────────────────

  Future<Either<Failure, T>> _wrap<T>(T Function() fn) async {
    try {
      return right(fn());
    } on StorageException catch (e) {
      return left(StorageFailure(e.message));
    } catch (e, st) {
      AppLogger.error('Settings read error', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> _wrapAsync(Future<void> Function() fn) async {
    try {
      await fn();
      return right(null);
    } on StorageException catch (e) {
      return left(StorageFailure(e.message));
    } catch (e, st) {
      AppLogger.error('Settings write error', tag: _tag, error: e, stackTrace: st);
      return left(UnexpectedFailure(e.toString()));
    }
  }
}
