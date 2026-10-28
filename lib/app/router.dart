import 'package:flutter/material.dart';

import '../features/calendar/presentation/calendar_screen.dart';
import '../features/display/presentation/animation_screen.dart';
import '../features/display/presentation/font_size_screen.dart';
import '../features/dns/presentation/dns_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/network/presentation/kill_switch_screen.dart';
import '../features/payment_qr/presentation/payment_qr_screen.dart';
import '../features/power/presentation/caffeine_screen.dart';
import '../features/profiles/data/profile_models.dart';
import '../features/profiles/presentation/profile_editor_screen.dart';
import '../features/profiles/presentation/profiles_screen.dart';
import '../features/quick_texts/presentation/quick_texts_screen.dart';
import '../features/screen_time/presentation/screen_time_screen.dart';

abstract final class AppRouter {
  static const root = '/';
  static const dns = '/dns';
  static const animation = '/animation';
  static const killSwitch = '/kill-switch';
  static const quickTexts = '/quick-texts';
  static const profiles = '/profiles';
  static const calendar = '/calendar';
  static const paymentQr = '/payment-qr';
  static const fontSize = '/font-size';
  static const caffeine = '/caffeine';
  static const appScreenTime = '/app-screen-time';

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
        'bs_date' => calendar,
        'payment_qr' => paymentQr,
        'font_size' => fontSize,
        'caffeine' => caffeine,
        'app_screen_time' => appScreenTime,
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
      calendar => const CalendarScreen(),
      paymentQr => const PaymentQrScreen(),
      fontSize => const FontSizeScreen(),
      caffeine => const CaffeineScreen(),
      appScreenTime => const AppScreenTimeScreen(),
      profileEditor => ProfileEditorScreen(editing: settings.arguments as Profile?),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
