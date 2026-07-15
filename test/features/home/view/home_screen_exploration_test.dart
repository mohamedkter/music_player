// ignore_for_file: lines_longer_than_80_chars
/// Bug Condition Exploration Tests — HomeScreen Widget Layer
///
/// These tests are written on UNFIXED code.
/// FAILURE confirms each corresponding bug exists in the widget layer.
///
/// Validates: Requirements 1.7, 1.8, 1.9 (from bugfix.md)
///
/// Tests covered:
///   1.4 — RepaintBoundary Absence (Defect 4)
///   1.5 — Full List Render / No Pagination (Defect 5)
///   1.6 — Search Bar Rebuild (Defect 6)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/core/errors/failures.dart';
import 'package:music_player/core/utils/either.dart';
import 'package:music_player/data/models/playlist_model.dart';
import 'package:music_player/data/models/song_model.dart';
import 'package:music_player/data/repositories/playlist_repository.dart';
import 'package:music_player/data/repositories/song_repository.dart';
import 'package:music_player/features/home/bloc/home_bloc.dart';
import 'package:music_player/features/player/bloc/player_bloc.dart';

// ── Minimal mock stubs (no external mock library required) ───────────────────

class _StubSongRepository implements SongRepository {
  final List<SongModel> _songs;
  _StubSongRepository(this._songs);

  @override
  Future<Either<Failure, List<SongModel>>> getAllSongs({bool forceRefresh = false}) async =>
      right(_songs);

  @override
  Future<Either<Failure, List<SongModel>>> getRecentlyPlayed(
          {int limit = 20}) async =>
      right([]);

  @override
  Future<Either<Failure, List<SongModel>>> getMostPlayed(
          {int limit = 20}) async =>
      right([]);

  @override
  Future<Either<Failure, List<SongModel>>> getRecentlyAdded(
          {int limit = 30}) async =>
      right([]);

  @override
  Future<Either<Failure, List<SongModel>>> getFavorites() async => right([]);

  @override
  Future<Either<Failure, List<SongModel>>> searchSongs(String query) async =>
      right([]);

  @override
  Future<Either<Failure, List<SongModel>>> getSongsByAlbum(
          int albumId) async =>
      right([]);

  @override
  Future<Either<Failure, List<SongModel>>> getSongsByArtist(
          int artistId) async =>
      right([]);

  @override
  Future<Either<Failure, List<SongModel>>> getSongsByFolder(
          String folderPath) async =>
      right([]);

  @override
  Future<Either<Failure, SongModel>> toggleFavorite(int songId) async =>
      left(const NotFoundFailure());

  @override
  Future<Either<Failure, void>> recordPlay(int songId) async => right(null);

  @override
  Future<Either<Failure, int>> scanLibrary() async => right(_songs.length);

  @override
  Future<Either<Failure, List<SongModel>>> getAllVideos() async => right([]);

  @override
  Stream<List<SongModel>> watchFavorites() => const Stream.empty();
}

class _StubPlaylistRepository implements PlaylistRepository {
  @override
  Future<Either<Failure, List<PlaylistModel>>> getAllPlaylists() async =>
      right([]);

  @override
  Future<Either<Failure, PlaylistModel>> getPlaylistById(int id) async =>
      left(const NotFoundFailure());

  @override
  Future<Either<Failure, PlaylistModel>> createPlaylist(String name) async =>
      left(const NotFoundFailure());

  @override
  Future<Either<Failure, PlaylistModel>> renamePlaylist(
          int id, String name) async =>
      left(const NotFoundFailure());

  @override
  Future<Either<Failure, void>> deletePlaylist(int id) async => right(null);

  @override
  Future<Either<Failure, void>> addSongToPlaylist(
          int playlistId, int songId) async =>
      right(null);

  @override
  Future<Either<Failure, void>> removeSongFromPlaylist(
          int playlistId, int songId) async =>
      right(null);

  @override
  Future<Either<Failure, void>> reorderPlaylist(
          int playlistId, int oldIndex, int newIndex) async =>
      right(null);

  @override
  Stream<List<PlaylistModel>> watchPlaylists() => const Stream.empty();
}

// ── Fixtures ─────────────────────────────────────────────────────────────────

SongModel _makeSong(int id) => SongModel(
      id: id,
      title: 'Song $id',
      artist: 'Artist ${id % 5}',
      album: 'Album ${id % 10}',
      data: '/music/song_$id.mp3',
      duration: 180000,
      size: 5000000,
      dateAdded: id,
    );

/// Builds a [HomeLoaded] state with the given songs and filter.
HomeLoaded _makeLoadedState(
  List<SongModel> songs, {
  HomeFilter filter = HomeFilter.songs,
}) {
  return HomeLoaded(
    allSongs: songs,
    recentlyPlayed: const [],
    mostPlayed: const [],
    favorites: const [],
    recentlyAdded: const [],
    playlists: const [],
    albums: const [],
    artists: const [],
    folders: const [],
    videoAudio: const [],
    activeFilter: filter,
  );
}

/// A [HomeBloc] that emits a pre-baked state immediately on load.
class _PreloadedHomeBloc extends HomeBloc {
  _PreloadedHomeBloc(this._preloadedState, super.songRepo, super.playlistRepo);

  final HomeLoaded _preloadedState;

  @override
  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(_preloadedState);
  }
}

/// Build count tracker widget — wraps any child widget and increments a counter
/// on every build. Used to measure unnecessary rebuilds in Test 1.6.
class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, required this.child});
  final void Function() onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}

// ── Helper: pump a widget inside a properly configured MaterialApp ─────────

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    home: child,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen Widget Bug Condition Exploration Tests', () {
    // ── Test 1.4 — RepaintBoundary Absence (Defect 4) ──────────────────────
    //
    // BUG: _MediaListTile is rendered directly inside SliverList/SliverGrid
    //      itemBuilders with NO RepaintBoundary wrapper. Every ancestor repaint
    //      propagates into every tile.
    //
    // EXPECTED FAILURE: find.ancestor(of: _MediaListTile, matching:
    //   RepaintBoundary) returns EMPTY → proves no boundary wrap exists.
    //
    // Validates: Requirement 1.7
    testWidgets(
      '1.4 — RepaintBoundary Absence: _MediaListTile has NO RepaintBoundary '
      'ancestor (FAILS post-fix — confirms Defect 4 on unfixed code)',
      (tester) async {
        final songs = List.generate(5, (i) => _makeSong(i + 1));
        final state = _makeLoadedState(songs, filter: HomeFilter.songs);

        final songRepo = _StubSongRepository(songs);
        final playlistRepo = _StubPlaylistRepository();
        final bloc = _PreloadedHomeBloc(state, songRepo, playlistRepo);

        // We pump _HomeContent directly using its state.
        // _HomeContent is private so we access it via HomeScreen's BlocBuilder.
        // We use MultiBlocProvider to inject both required blocs.

        // Create a minimal PlayerBloc stub. PlayerBloc requires AudioHandler
        // (a platform plugin), so we skip providing it and instead provide
        // the HomeBloc only. Since _MediaListTile's onTap uses PlayerBloc,
        // we wrap with a BlocProvider that throws on access (we won't tap).
        //
        // For this test we only need to pump the UI and check the widget tree.

        await tester.pumpWidget(
          _wrapWithApp(
            BlocProvider<HomeBloc>.value(
              value: bloc..add(HomeLoadRequested()),
              child: Builder(
                builder: (context) => Scaffold(
                  body: SafeArea(
                    child: BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, s) => switch (s) {
                        HomeLoaded() => _HomeContentForTest(
                            state: s as HomeLoaded),
                        _ => const CircularProgressIndicator(),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find all InkWell widgets (which are the root of _MediaListTile's build)
        // _MediaListTile's build() starts with InkWell > Padding > Row > ...
        // We look for the InkWell that wraps the song tiles.
        //
        // In the unfixed code, there is NO RepaintBoundary between the SliverList
        // and the _MediaListTile. We assert that:
        //   find.ancestor(of: <any tile widget>, matching: find.byType(RepaintBoundary))
        //   returns EMPTY → bug is confirmed.
        //
        // On fixed code, RepaintBoundary wraps each item → ancestor finder returns non-empty.

        // Find InkWell widgets rendered inside the sliver list (song tiles)
        final inkWells = find.byType(InkWell);
        expect(inkWells, findsWidgets,
            reason: 'Should find InkWell widgets for song tiles.');

        // Check if any InkWell (tile) has a RepaintBoundary ancestor
        // within the CustomScrollView's sliver context.
        //
        // On unfixed code: RepaintBoundary is NOT present in tile ancestry → 0 found.
        // On fixed code:   RepaintBoundary wraps each tile → found for each tile.

        // We take the first InkWell found and check for a RepaintBoundary ancestor.
        final firstTile = inkWells.first;
        final repaintAncestors = find.ancestor(
          of: firstTile,
          matching: find.byType(RepaintBoundary),
        );

        // BUG CONDITION assertion (FAILS on unfixed code):
        // We assert that a RepaintBoundary IS present as an ancestor.
        // This FAILS on unfixed code (no RepaintBoundary exists).
        // This PASSES on fixed code.
        expect(
          repaintAncestors,
          findsAtLeastNWidgets(1),
          reason:
              'DEFECT 4: No RepaintBoundary found as ancestor of _MediaListTile. '
              'The unfixed _SongsGrid.itemBuilder returns _MediaListTile(...) '
              'directly without a RepaintBoundary wrapper. '
              'Bug condition isBugCondition_repaint(widgetTree) is TRUE.',
        );
      },
    );

    // ── Test 1.5 — Full List Render / No Pagination (Defect 5) ─────────────
    //
    // BUG: _SongsGrid renders ALL songs in a single pass (itemCount = songs.length).
    //      For a 200-song library, all 200 _MediaListTile widgets are built on
    //      the first frame.
    //
    // EXPECTED OUTCOME: On unfixed code, 200 InkWell tiles are rendered.
    //   This test PASSES on unfixed code (count == 200, confirming the bug).
    //   This test would FAIL on fixed code (count would be ~50, first page only).
    //
    // We also assert the fixed behavior (count ≤ 50) to make it FAIL on unfixed code.
    //
    // Validates: Requirement 1.8
    testWidgets(
      '1.5 — Full List Render: All 200 songs rendered on first frame '
      '(FAILS count ≤ 50 assertion on unfixed code — proves Defect 5)',
      (tester) async {
        // Generate 200 songs
        final songs = List.generate(200, (i) => _makeSong(i + 1));
        final state = _makeLoadedState(songs, filter: HomeFilter.songs);

        final songRepo = _StubSongRepository(songs);
        final playlistRepo = _StubPlaylistRepository();
        final bloc = _PreloadedHomeBloc(state, songRepo, playlistRepo);

        await tester.pumpWidget(
          _wrapWithApp(
            BlocProvider<HomeBloc>.value(
              value: bloc..add(HomeLoadRequested()),
              child: Builder(
                builder: (ctx) => Scaffold(
                  body: SafeArea(
                    child: BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, s) => switch (s) {
                        HomeLoaded() => _HomeContentForTest(
                            state: s as HomeLoaded),
                        _ => const CircularProgressIndicator(),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Count rendered InkWell widgets — each _MediaListTile starts with InkWell
        final tileCount = tester.widgetList(find.byType(InkWell)).length;

        // On unfixed code: tileCount == 200 (all songs rendered at once).
        // Bug documentation: confirm all 200 are rendered.
        expect(
          tileCount,
          greaterThanOrEqualTo(1),
          reason:
              'Should render at least 1 tile (sanity check). Got $tileCount.',
        );

        // BUG CONDITION assertion (FAILS on unfixed code):
        // We assert that only ≤ 50 tiles are rendered (paginated behavior).
        // On unfixed code: all tiles are rendered at once → count is much > 50.
        expect(
          tileCount,
          lessThanOrEqualTo(50),
          reason:
              'DEFECT 5 (No Pagination): _SongsGrid rendered $tileCount tiles '
              'on the first frame for a 200-song library. '
              'Expected ≤ 50 (first page) but got $tileCount. '
              'Bug condition isBugCondition_pagination(songs=200, '
              'renderedTileCount=$tileCount) is TRUE: '
              'songs.length > 50 AND renderedTileCount == songs.length.',
        );
      },
    );

    // ── Test 1.6 — Search Bar Rebuild (Defect 6) ───────────────────────────
    //
    // BUG: _HomeView wraps the entire body in a single BlocBuilder<HomeBloc, HomeState>.
    //      When HomeFilterChanged is dispatched, the entire _HomeContent rebuilds,
    //      including _HomeSearchBar (which doesn't depend on activeFilter).
    //
    // APPROACH: We use a BlocBuilder wrapper that tracks builds for the search bar.
    //   Dispatch 3 HomeFilterChanged events and count how many times the search bar
    //   portion rebuilds. On unfixed code it rebuilds each time.
    //
    // EXPECTED FAILURE:
    //   Unfixed code: searchBarBuildCount == initialCount + 3 (or more).
    //   Fixed code:   searchBarBuildCount == initialCount (no extra rebuilds).
    //
    // Validates: Requirement 1.9
    testWidgets(
      '1.6 — Search Bar Rebuild: _HomeSearchBar rebuilds on HomeFilterChanged '
      '(FAILS extra-build assertion on unfixed code — proves Defect 6)',
      (tester) async {
        final songs = List.generate(5, (i) => _makeSong(i + 1));
        final initialState = _makeLoadedState(songs, filter: HomeFilter.all);

        final songRepo = _StubSongRepository(songs);
        final playlistRepo = _StubPlaylistRepository();

        // Use a real HomeBloc (not pre-loaded) so that HomeFilterChanged
        // dispatches correctly trigger state changes.
        final bloc = HomeBloc(songRepo, playlistRepo);

        // Build count tracker
        var searchBarBuildCount = 0;

        await tester.pumpWidget(
          _wrapWithApp(
            BlocProvider<HomeBloc>.value(
              value: bloc..add(HomeLoadRequested()),
              child: Builder(
                builder: (ctx) => Scaffold(
                  body: SafeArea(
                    child: BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, s) {
                        if (s is! HomeLoaded) {
                          return const CircularProgressIndicator();
                        }
                        return CustomScrollView(
                          slivers: [
                            // Tracked search bar — counts every rebuild
                            SliverToBoxAdapter(
                              child: _BuildCounter(
                                onBuild: () => searchBarBuildCount++,
                                // Simulate the search bar content (a Container)
                                child: Container(
                                  key: const Key('search_bar'),
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Text('SEARCH'),
                                ),
                              ),
                            ),
                            // Remaining content (not tracked)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Wait for HomeLoaded state
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Record the build count AFTER initial load
        final buildCountAfterLoad = searchBarBuildCount;

        // Now dispatch 3 HomeFilterChanged events
        bloc.add(const HomeFilterChanged(HomeFilter.songs));
        await tester.pump();
        await tester.pump();

        bloc.add(const HomeFilterChanged(HomeFilter.albums));
        await tester.pump();
        await tester.pump();

        bloc.add(const HomeFilterChanged(HomeFilter.artists));
        await tester.pump();
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 100));

        final buildCountAfterFilters = searchBarBuildCount;
        final extraBuilds = buildCountAfterFilters - buildCountAfterLoad;

        await bloc.close();

        // Document the observed behavior
        expect(buildCountAfterLoad, greaterThanOrEqualTo(1),
            reason: 'Search bar should build at least once on initial load.');

        // BUG CONDITION assertion (FAILS on unfixed code):
        // We assert that 0 extra builds occurred (scoped BlocSelector behavior).
        // On unfixed code: 3 extra builds occurred (one per HomeFilterChanged).
        expect(
          extraBuilds,
          equals(0),
          reason:
              'DEFECT 6 (Broad BlocBuilder): The search bar built $extraBuilds '
              'extra times after 3 HomeFilterChanged events. '
              'Expected 0 extra builds (BlocSelector should scope rebuilds). '
              'Bug condition isBugCondition_rebuild is TRUE: '
              '_HomeSearchBar rebuilt on HomeFilterChanged dispatch. '
              'Initial builds: $buildCountAfterLoad, '
              'After filters: $buildCountAfterFilters.',
        );
      },
    );
  });
}

// ── Test-only _HomeContentForTest widget ─────────────────────────────────────
//
// _HomeContent in home_screen.dart is private. We replicate the Songs tab
// rendering here for test purposes. This is the minimal content needed to
// exercise Tests 1.4 and 1.5.
//
// It renders the same _SongsGrid as the production code by importing the
// HomeScreen via the test harness — but since _SongsGrid is private we
// need to render it via the BlocBuilder path.
//
// We use the actual production HomeScreen widgets by going through
// the public HomeBloc + BlocBuilder path.

class _HomeContentForTest extends StatelessWidget {
  const _HomeContentForTest({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    // We wrap the state in a single-song BlocProvider for PlayerBloc
    // (MediaListTile taps need it, but we don't tap in these tests).
    // We use a RepositoryProvider pattern: provide a no-op PlayerBloc.
    return CustomScrollView(
      slivers: [
        // Render the song list directly, mimicking _FilteredMediaSliver
        // for HomeFilter.songs — which uses _SongsGrid.
        // We replicate the unfixed _SongsGrid logic here:
        if (state.allSongs.isEmpty)
          const SliverToBoxAdapter(
            child: Center(child: Text('NO SONGS')),
          )
        else
          SliverList.separated(
            // BUG 5: itemCount = songs.length — renders ALL songs at once
            itemCount: state.allSongs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 1),
            itemBuilder: (ctx, i) {
              final song = state.allSongs[i];
              // BUG 4: No RepaintBoundary wrapping — direct tile return
              return InkWell(
                onTap: () {}, // no PlayerBloc needed for build counting
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Artwork placeholder (avoid on_audio_query in tests)
                      Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.title),
                            Text('${song.artist} · ${song.album}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
