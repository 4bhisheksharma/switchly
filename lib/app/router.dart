import 'package:flutter/material.dart';

import '../features/display/presentation/animation_screen.dart';
import '../features/dns/presentation/dns_screen.dart';
import '../features/home/presentation/home_screen.dart';

abstract final class AppRouter {
  static const root = '/';
  static const dns = '/dns';
  static const animation = '/animation';

  /// Native launch routes (see LaunchRoutes.kt). These are handled by the app, not pushed.
  static const setupLaunch = '/setup';
  static const tileLaunchPrefix = '/tile/';

  /// The config screen for a tile id from a long-press, if it has one.
  static String? routeForTile(String tileId) => switch (tileId) {
        'private_dns' => dns,
        'animation_speed' => animation,
        _ => null,
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      root => const HomeScreen(),
      dns => const DnsScreen(),
      animation => const AnimationScreen(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
