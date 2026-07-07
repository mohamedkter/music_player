import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_album_datasource.dart';
import '../../data/datasources/local_song_datasource.dart';
import '../../data/datasources/preferences_datasource.dart';
import '../../data/repositories/impl/settings_repository_impl.dart';
import '../../data/repositories/impl/song_repository_impl.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../bloc/theme/theme_bloc.dart';
import '../utils/logger.dart';

/// Global service locator — single instance accessed via [sl].
/// All registrations follow Dependency Inversion:
///   BLoCs → abstract interfaces
///   Interfaces → concrete implementations wired here only
final GetIt sl = GetIt.instance;

/// Called once from [main] before [runApp].
Future<void> configureDependencies() async {
  // ── External ──────────────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ── Data Sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<PreferencesDataSource>(
    () => PreferencesDataSource(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<LocalSongDataSource>(
    () => LocalSongDataSource(),
  );
  sl.registerLazySingleton<LocalAlbumDataSource>(
    () => LocalAlbumDataSource(),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(
      dataSource: sl<LocalSongDataSource>(),
      prefs: sl<PreferencesDataSource>(),
    ),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<PreferencesDataSource>()),
  );

  // ── Core BLoCs (singletons — survive navigation) ──────────────────────────
  sl.registerLazySingleton<ThemeBloc>(
    () => ThemeBloc(sl<SharedPreferences>()),
  );

  AppLogger.info('All dependencies registered', tag: 'DI');
}
