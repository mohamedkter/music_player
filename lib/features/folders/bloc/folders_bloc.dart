import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../core/utils/logger.dart';

part 'folders_event.dart';
part 'folders_state.dart';

class FoldersBloc extends Bloc<FoldersEvent, FoldersState> {
  FoldersBloc(this._repository) : super(FoldersInitial()) {
    on<FoldersLoadRequested>(_onLoad);
  }

  final SongRepository _repository;
  static const _tag = 'FoldersBloc';

  Future<void> _onLoad(
    FoldersLoadRequested event,
    Emitter<FoldersState> emit,
  ) async {
    emit(FoldersLoading());
    final result = await _repository.getAllSongs();
    result.fold(
      (f) {
        AppLogger.error(f.message, tag: _tag);
        emit(FoldersError(f.message));
      },
      (songs) {
        // Group songs by folder path
        final folderMap = <String, List<SongModel>>{};
        for (final song in songs) {
          folderMap.putIfAbsent(song.folderPath, () => []).add(song);
        }

        final folders = folderMap.entries
            .map(
              (e) => FolderEntry(
                name: e.key.split('/').last,
                path: e.key,
                songs: e.value,
              ),
            )
            .toList()
          // Sort by song count descending
          ..sort((a, b) => b.songCount.compareTo(a.songCount));

        emit(FoldersLoaded(folders: folders));
      },
    );
  }
}
