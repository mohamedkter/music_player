import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Centralized logger that wraps `dart:developer`.
/// In release builds, logs are silenced automatically.
///
/// Usage:
/// ```dart
/// AppLogger.info('Songs loaded', tag: 'SongRepository');
/// AppLogger.error('DB write failed', error: e, stackTrace: st);
/// ```
abstract final class AppLogger {
  static void info(
    String message, {
    String tag = 'App',
    Object? extra,
  }) {
    if (kDebugMode) {
      dev.log('[ℹ] $message', name: tag, error: extra);
    }
  }

  static void warning(
    String message, {
    String tag = 'App',
    Object? extra,
  }) {
    if (kDebugMode) {
      dev.log('[⚠] $message', name: tag, error: extra);
    }
  }

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        '[✖] $message',
        name: tag,
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  static void debug(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      dev.log('[⬜] $message', name: tag);
    }
  }
}
