import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract interface class SettingsRepository {
  Future<Either<Failure, ThemeMode>> getThemeMode();
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);

  Future<Either<Failure, Color>> getAccentColor();
  Future<Either<Failure, void>> saveAccentColor(Color color);

  Future<Either<Failure, bool>> getDynamicColorEnabled();
  Future<Either<Failure, void>> saveDynamicColorEnabled(bool value);

  Future<Either<Failure, bool>> getIgnoreShortAudio();
  Future<Either<Failure, void>> saveIgnoreShortAudio(bool value);

  Future<Either<Failure, int>> getMinAudioDuration();
  Future<Either<Failure, void>> saveMinAudioDuration(int seconds);

  Future<Either<Failure, List<String>>> getExcludedFolders();
  Future<Either<Failure, void>> saveExcludedFolders(List<String> folders);

  Future<Either<Failure, double>> getPlaybackSpeed();
  Future<Either<Failure, void>> savePlaybackSpeed(double speed);

  Future<Either<Failure, int>> getRepeatMode();
  Future<Either<Failure, void>> saveRepeatMode(int mode);

  Future<Either<Failure, bool>> getShuffleEnabled();
  Future<Either<Failure, void>> saveShuffleEnabled(bool value);

  Future<Either<Failure, int>> getLastSongId();
  Future<Either<Failure, void>> saveLastSongId(int id);

  Future<Either<Failure, int>> getLastPosition();
  Future<Either<Failure, void>> saveLastPosition(int ms);
}
