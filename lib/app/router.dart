import 'package:flutter/material.dart';

import '../features/setup/presentation/add_tiles_screen.dart';
import 'app_shell.dart';

abstract final class AppRouter {
  static const root = '/';
  static const addTiles = '/add-tiles';

  /// Native launch routes (see LaunchRoutes.kt). These are handled by the app, not pushed.
  static const setupLaunch = '/setup';
  static const tileLaunchPrefix = '/tile/';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      root => const AppShell(),
      addTiles => const AddTilesScreen(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
