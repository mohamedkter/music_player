part of 'player_bloc.dart';

sealed class PlayerEvent {}

final class PlayerSongRequested extends PlayerEvent {
  PlayerSongRequested({required this.song, required this.queue});
  final SongModel song;
  final List<SongModel> queue;
}

final class PlayerTogglePlayPause extends PlayerEvent {}

final class PlayerSkipToNext extends PlayerEvent {}

final class PlayerSkipToPrevious extends PlayerEvent {}

final class PlayerSeekRequested extends PlayerEvent {
  PlayerSeekRequested(this.position);
  final Duration position;
}

final class PlayerShuffleToggled extends PlayerEvent {}

final class PlayerRepeatToggled extends PlayerEvent {}

final class PlayerSpeedChanged extends PlayerEvent {
  PlayerSpeedChanged(this.speed);
  final double speed;
}

final class PlayerQueueReordered extends PlayerEvent {
  PlayerQueueReordered({required this.oldIndex, required this.newIndex});
  final int oldIndex;
  final int newIndex;
}

final class PlayerSongRemovedFromQueue extends PlayerEvent {
  PlayerSongRemovedFromQueue(this.index);
  final int index;
}

final class PlayerFavoriteToggled extends PlayerEvent {}

/// Internal — emitted by position stream subscription.
final class _PlayerPositionUpdated extends PlayerEvent {
  _PlayerPositionUpdated(this.position);
  final Duration position;
}

/// Internal — emitted when playback state changes.
final class _PlayerStateUpdated extends PlayerEvent {
  _PlayerStateUpdated({required this.isPlaying, required this.duration});
  final bool isPlaying;
  final Duration duration;
}

final class PlayerSleepTimerStarted extends PlayerEvent {
  PlayerSleepTimerStarted(this.duration);
  final Duration duration;
}

final class PlayerSleepTimerCancelled extends PlayerEvent {}

final class _PlayerSleepTimerTicked extends PlayerEvent {
  _PlayerSleepTimerTicked(this.remaining);
  final Duration? remaining;
}

final class PlayerQueueCleared extends PlayerEvent {}

final class _PlayerMediaItemChanged extends PlayerEvent {
  _PlayerMediaItemChanged(this.item);
  final MediaItem item;
}

final class PlayerInitializeRequested extends PlayerEvent {}

final class PlayerDancerChanged extends PlayerEvent {
  PlayerDancerChanged(this.dancerPath);
  final String dancerPath;
}
