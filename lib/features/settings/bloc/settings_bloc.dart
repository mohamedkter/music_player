import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/bloc/theme/theme_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../core/utils/logger.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required SettingsRepository settingsRepository,
    required SongRepository songRepository,
    required ThemeBloc themeBloc,
  })  : _settings = settingsRepository,
        _songs = songRepository,
        _themeBloc = themeBloc,
        super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsAccentColorChanged>(_onAccentChanged);
    on<SettingsDynamicColorToggled>(_onDynamicColorToggled);
    on<SettingsIgnoreShortAudioToggled>(_onIgnoreShortToggled);
    on<SettingsMinDurationChanged>(_onMinDurationChanged);
    on<SettingsFolderExcluded>(_onFolderExcluded);
    on<SettingsFolderIncluded>(_onFolderIncluded);
    on<SettingsScanRequested>(_onScan);
  }

  final SettingsRepository _settings;
  final SongRepository _songs;
  final ThemeBloc _themeBloc;
  static const _tag = 'SettingsBloc';

  Future<void> _onLoad(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final results = await Future.wait([
      _settings.getThemeMode(),
      _settings.getAccentColor(),
      _settings.getDynamicColorEnabled(),
      _settings.getIgnoreShortAudio(),
      _settings.getMinAudioDuration(),
      _settings.getExcludedFolders(),
    ]);

    emit(state.copyWith(
      themeMode: results[0].fold((_) => ThemeMode.system, (v) => v as ThemeMode),
      accentColor: results[1].fold((_) => const Color(0xFF6240C9), (v) => v as Color),
      dynamicColorEnabled: results[2].fold((_) => true, (v) => v as bool),
      ignoreShortAudio: results[3].fold((_) => true, (v) => v as bool),
      minAudioDuration: results[4].fold((_) => 30, (v) => v as int),
      excludedFolders: results[5].fold((_) => <String>[], (v) => v as List<String>),
    ));
  }

  Future<void> _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.mode));
    _themeBloc.add(ThemeModeChanged(event.mode));
    await _settings.saveThemeMode(event.mode);
  }

  Future<void> _onAccentChanged(
    SettingsAccentColorChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(accentColor: event.color));
    await _settings.saveAccentColor(event.color);
  }

  Future<void> _onDynamicColorToggled(
    SettingsDynamicColorToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final next = !state.dynamicColorEnabled;
    emit(state.copyWith(dynamicColorEnabled: next));
    await _settings.saveDynamicColorEnabled(next);
  }

  Future<void> _onIgnoreShortToggled(
    SettingsIgnoreShortAudioToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final next = !state.ignoreShortAudio;
    emit(state.copyWith(ignoreShortAudio: next));
    await _settings.saveIgnoreShortAudio(next);
  }

  Future<void> _onMinDurationChanged(
    SettingsMinDurationChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(minAudioDuration: event.seconds));
    await _settings.saveMinAudioDuration(event.seconds);
  }

  Future<void> _onFolderExcluded(
    SettingsFolderExcluded event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.excludedFolders.contains(event.path)) return;
    final updated = [...state.excludedFolders, event.path];
    emit(state.copyWith(excludedFolders: updated));
    await _settings.saveExcludedFolders(updated);
  }

  Future<void> _onFolderIncluded(
    SettingsFolderIncluded event,
    Emitter<SettingsState> emit,
  ) async {
    final updated =
        state.excludedFolders.where((f) => f != event.path).toList();
    emit(state.copyWith(excludedFolders: updated));
    await _settings.saveExcludedFolders(updated);
  }

  Future<void> _onScan(
    SettingsScanRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isScanning: true));
    final result = await _songs.scanLibrary();
    result.fold(
      (f) {
        AppLogger.error(f.message, tag: _tag);
        emit(state.copyWith(isScanning: false));
      },
      (count) => emit(state.copyWith(isScanning: false, lastScanCount: count)),
    );
  }
}
