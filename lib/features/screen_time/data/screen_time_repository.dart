import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';
import 'screen_time_config.dart';

class AppUsageItem {
  const AppUsageItem({
    required this.package,
    required this.label,
    required this.icon,
    required this.usageMillis,
    required this.formattedUsage,
  });

  final String package;
  final String label;
  final Uint8List icon;
  final int usageMillis;
  final String formattedUsage;
}

class ScreenTimeRepository {
  const ScreenTimeRepository(this.channel);

  final QsChannel channel;

  Future<bool> hasUsageAccess() => channel.hasUsageAccess();

  Future<bool> openUsageAccessSettings() => channel.openUsageAccessSettings();

  Future<({int millis, String formatted})> getAppScreenTime(String packageName) =>
      channel.getAppScreenTime(packageName);

  Future<Map<String, int>> getTodayUsageStats() => channel.getTodayUsageStats();

  Future<List<({String package, String label, Uint8List icon})>> getLaunchableApps() =>
      channel.getLaunchableApps();

  Future<ScreenTimeConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.appUsageConfig);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ScreenTimeConfig.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(ScreenTimeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.appUsageConfig, config.toJson());
    await channel.refreshAppScreenTimeTile();
  }

  static String formatMillis(int totalMillis) {
    final totalSeconds = totalMillis ~/ 1000;
    final minutes = (totalSeconds ~/ 60) % 60;
    final hours = totalSeconds ~/ 3600;

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    if (totalSeconds > 0) return '< 1m';
    return '0m';
  }
}
