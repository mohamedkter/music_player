import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System chrome ──────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Dependency injection ───────────────────────────────────────────────────
  await configureDependencies();
  AppLogger.info('App starting', tag: 'Main');

  // ── BLoC observer — logs transitions in debug builds only ─────────────────
  assert(() {
    Bloc.observer = _AppBlocObserver();
    return true;
  }());

  runApp(const App());
}

/// Debug-only BLoC observer.
/// Logs every state transition and error to the console.
class _AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    AppLogger.debug(
      '${bloc.runtimeType}: ${change.currentState.runtimeType} → '
      '${change.nextState.runtimeType}',
      tag: 'BLoC',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace st) {
    super.onError(bloc, error, st);
    AppLogger.error(
      '${bloc.runtimeType} threw an error',
      tag: 'BLoC',
      error: error,
      stackTrace: st,
    );
  }
}
