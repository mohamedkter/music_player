import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../utils/logger.dart';

part 'theme_event.dart';
part 'theme_state.dart';

/// Manages app-wide theme mode.
/// Persists the selection to [SharedPreferences].
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(this._prefs) : super(const ThemeState()) {
    on<ThemeModeChanged>(_onModeChanged);
    on<ThemeToggled>(_onToggled);
    _loadSavedTheme();
  }

  final SharedPreferences _prefs;

  void _loadSavedTheme() {
    final index = _prefs.getInt(AppConstants.prefThemeMode);
    if (index != null && index < ThemeMode.values.length) {
      add(ThemeModeChanged(ThemeMode.values[index]));
    }
  }

  Future<void> _onModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(mode: event.mode));
    await _persist(event.mode);
  }

  Future<void> _onToggled(
    ThemeToggled event,
    Emitter<ThemeState> emit,
  ) async {
    final next = state.mode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(state.copyWith(mode: next));
    await _persist(next);
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      await _prefs.setInt(AppConstants.prefThemeMode, mode.index);
    } catch (e, st) {
      AppLogger.error('Failed to persist theme', tag: 'ThemeBloc', error: e, stackTrace: st);
    }
  }
}
