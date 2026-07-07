part of 'player_bloc.dart';

enum RepeatMode { off, one, all }

final class PlayerState extends Equatable {
  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.speed = 1.0,
    this.isLoading = false,
    this.errorMessage,
    this.sleepTimerRemaining,
    this.primaryColor,
    this.secondaryColor,
  });

  final SongModel? currentSong;
  final List<SongModel> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final double speed;
  final bool isLoading;
  final String? errorMessage;
  final Duration? sleepTimerRemaining;
  final Color? primaryColor;
  final Color? secondaryColor;

  bool get hasError => errorMessage != null;
  bool get hasSong => currentSong != null;
  bool get isSleepTimerActive => sleepTimerRemaining != null;

  double get progress =>
      duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;

  PlayerState copyWith({
    SongModel? currentSong,
    List<SongModel>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    double? speed,
    bool? isLoading,
    String? errorMessage,
    Duration? sleepTimerRemaining,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      speed: speed ?? this.speed,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      sleepTimerRemaining: sleepTimerRemaining ?? this.sleepTimerRemaining,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }

  /// Helper to clear nullable fields specifically
  PlayerState copyWithClearedSleepTimer() {
    return PlayerState(
      currentSong: currentSong,
      queue: queue,
      currentIndex: currentIndex,
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      shuffleEnabled: shuffleEnabled,
      repeatMode: repeatMode,
      speed: speed,
      isLoading: isLoading,
      errorMessage: errorMessage,
      sleepTimerRemaining: null,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
  }

  @override
  List<Object?> get props => [
        currentSong,
        queue,
        currentIndex,
        isPlaying,
        position,
        duration,
        shuffleEnabled,
        repeatMode,
        speed,
        isLoading,
        errorMessage,
        sleepTimerRemaining,
        primaryColor,
        secondaryColor,
      ];
}
