/// Central registry of every named route in the app.
///
/// Usage:
/// ```dart
/// Navigator.pushNamed(context, AppRoutes.nowPlaying);
/// Navigator.pushNamed(context, AppRoutes.categorySongs, arguments: CategorySongsArgs(...));
/// ```
abstract final class AppRoutes {
  // ── Modal / pushed screens ─────────────────────────────────────────────────
  static const String nowPlaying = '/now-playing';
  static const String queue = '/queue';
  static const String categorySongs = '/category-songs';
  static const String playlists = '/playlists';
  static const String search = '/search';
  static const String albums = '/albums';
  static const String albumDetail = '/albums/detail';
  static const String artistDetail = '/artists/detail';
  static const String artists = '/artists';
  static const String folders = '/folders';

  AppRoutes._();
}
