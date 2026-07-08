import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';

import '../utils/audio_handler.dart';
import '../../data/datasources/local_album_datasource.dart';
import '../../data/datasources/local_artist_datasource.dart';
import '../../data/datasources/local_song_datasource.dart';
import '../../data/datasources/preferences_datasource.dart';
import '../../data/repositories/album_repository.dart';
import '../../data/repositories/artist_repository.dart';
import '../../data/repositories/impl/album_repository_impl.dart';
import '../../data/repositories/impl/artist_repository_impl.dart';
import '../../data/repositories/impl/settings_repository_impl.dart';
import '../../data/repositories/impl/song_repository_impl.dart';
import '../../data/repositories/impl/playlist_repository_impl.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/repositories/playlist_repository.dart';
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

  final audioHandler = await initAudioService();
  sl.registerSingleton<AudioHandler>(audioHandler);

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
  sl.registerLazySingleton<LocalArtistDataSource>(
    () => LocalArtistDataSource(),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(
      dataSource: sl<LocalSongDataSource>(),
      prefs: sl<PreferencesDataSource>(),
    ),
  );
  sl.registerLazySingleton<AlbumRepository>(
    () => AlbumRepositoryImpl(dataSource: sl<LocalAlbumDataSource>()),
  );
  sl.registerLazySingleton<ArtistRepository>(
    () => ArtistRepositoryImpl(dataSource: sl<LocalArtistDataSource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<PreferencesDataSource>()),
  );
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(sl<SharedPreferences>(), sl<SongRepository>()),
  );

  // ── Core BLoCs (singletons — survive navigation) ──────────────────────────
  sl.registerLazySingleton<ThemeBloc>(
    () => ThemeBloc(sl<SharedPreferences>()),
  );

  AppLogger.info('All dependencies registered', tag: 'DI');
}
