part of 'folders_bloc.dart';

sealed class FoldersEvent extends Equatable {
  const FoldersEvent();
  @override
  List<Object?> get props => [];
}

final class FoldersLoadRequested extends FoldersEvent {}
