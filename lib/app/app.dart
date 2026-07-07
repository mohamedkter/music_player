import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/bloc/theme/theme_bloc.dart';
import '../core/di/service_locator.dart';
import '../core/theme/app_theme.dart';
import 'shell/app_shell.dart';

/// Root application widget.
///
/// Responsibilities (and only these):
/// - Provide the [ThemeBloc] singleton from DI
/// - React to theme changes via [BlocBuilder]
/// - Hand off to [AppShell] for all navigation
///
/// No business logic lives here.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeBloc>.value(
      value: sl<ThemeBloc>(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (_, themeState) => MaterialApp(
          title: 'Music Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeState.mode,
          home: const AppShell(),
        ),
      ),
    );
  }
}
