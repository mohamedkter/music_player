part of 'folders_bloc.dart';

/// Represents a single folder entry derived from song paths.
class FolderEntry extends Equatable {
  const FolderEntry({
    required this.name,
    required this.path,
    required this.songs,
  });

  final String name;
  final String path;
  final List<SongModel> songs;

  int get songCount => songs.length;

  @override
  List<Object?> get props => [path];
}

sealed class FoldersState extends Equatable {
  const FoldersState();
  @override
  List<Object?> get props => [];
}

final class FoldersInitial extends FoldersState {}

final class FoldersLoading extends FoldersState {}

final class FoldersLoaded extends FoldersState {
  const FoldersLoaded({required this.folders});

  final List<FolderEntry> folders;

  @override
  List<Object?> get props => [folders];
}

final class FoldersError extends FoldersState {
  const FoldersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
