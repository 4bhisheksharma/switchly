import 'package:flutter/material.dart';

import '../features/display/presentation/animation_screen.dart';
import '../features/dns/presentation/dns_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/network/presentation/kill_switch_screen.dart';
import '../features/profiles/data/profile_models.dart';
import '../features/profiles/presentation/profile_editor_screen.dart';
import '../features/profiles/presentation/profiles_screen.dart';
import '../features/quick_texts/presentation/quick_texts_screen.dart';

abstract final class AppRouter {
  static const root = '/';
  static const dns = '/dns';
  static const animation = '/animation';
  static const killSwitch = '/kill-switch';
  static const quickTexts = '/quick-texts';
  static const profiles = '/profiles';

  /// Pass the [Profile] to edit as `arguments`, or nothing to create one.
  static const profileEditor = '/profiles/edit';

  /// Native launch routes (see LaunchRoutes.kt). These are handled by the app, not pushed.
  static const setupLaunch = '/setup';
  static const tileLaunchPrefix = '/tile/';

  /// The config screen for a tile id from a long-press, if it has one.
  static String? routeForTile(String tileId) => switch (tileId) {
        'private_dns' => dns,
        'animation_speed' => animation,
        'kill_switch' => killSwitch,
        'quick_texts' => quickTexts,
        'profiles' => profiles,
        _ => null,
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      root => const HomeScreen(),
      dns => const DnsScreen(),
      animation => const AnimationScreen(),
      killSwitch => const KillSwitchScreen(),
      quickTexts => const QuickTextsScreen(),
      profiles => const ProfilesScreen(),
      profileEditor => ProfileEditorScreen(editing: settings.arguments as Profile?),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
