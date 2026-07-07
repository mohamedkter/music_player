part of 'theme_bloc.dart';

final class ThemeState extends Equatable {
  const ThemeState({this.mode = ThemeMode.system});

  final ThemeMode mode;

  ThemeState copyWith({ThemeMode? mode}) =>
      ThemeState(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
