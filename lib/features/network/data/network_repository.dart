import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';

/// An installed app, for the kill switch exception picker.
class InstalledApp extends Equatable {
  const InstalledApp({required this.package, required this.label, required this.icon});

  final String package;
  final String label;
  final Uint8List icon;

  @override
  List<Object?> get props => [package];
}

/// Live state of the network tiles.
class NetworkStatus extends Equatable {
  const NetworkStatus({
    required this.wirelessSupported,
    required this.wirelessDebugging,
    required this.devOptions,
    required this.address,
    required this.killSwitch,
  });

  final bool wirelessSupported;
  final bool wirelessDebugging;
  final bool devOptions;

  /// `ip:port`, just the IP when the port isn't readable, or null without Wi-Fi.
  final String? address;
  final bool killSwitch;

  bool get hasPort => address?.contains(':') ?? false;

  @override
  List<Object?> get props => [wirelessSupported, wirelessDebugging, devOptions, address, killSwitch];
}

/// Wireless debugging and the kill switch (its exception list lives in SharedPreferences).
class NetworkRepository {
  const NetworkRepository(this._channel);

  final QsChannel _channel;

  Future<NetworkStatus> readStatus() async {
    final s = await _channel.getNetworkState();
    return NetworkStatus(
      wirelessSupported: s.wirelessSupported,
      wirelessDebugging: s.wirelessDebugging,
      devOptions: s.devOptions,
      address: s.address,
      killSwitch: s.killSwitch,
    );
  }

  Future<bool> setWirelessDebugging(bool on) => _channel.setWirelessDebugging(on);

  Future<bool> setKillSwitch(bool on) => on ? _channel.startKillSwitch() : _channel.stopKillSwitch();

  Future<List<String>> loadAllowedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.killSwitchConfig);
    if (raw == null) return const [];
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return [for (final p in json['allowedApps'] as List? ?? const []) p as String];
    } on Object {
      return const [];
    }
  }

  /// Saves the list and re-applies it if the kill switch is running.
  Future<void> saveAllowedApps(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.killSwitchConfig, jsonEncode({'allowedApps': packages}));
    await _channel.reloadKillSwitch();
  }

  Future<List<InstalledApp>> loadInstalledApps() async => [
        for (final a in await _channel.getLaunchableApps())
          InstalledApp(package: a.package, label: a.label, icon: a.icon),
      ];
}
