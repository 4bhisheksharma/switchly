import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';

class PublicModeConfig extends Equatable {
  const PublicModeConfig({
    this.timeoutMinutes = 10,
    this.hiddenTiles = const ['payment_qr', 'quick_texts', 'wireless_debugging'],
    this.blockedPackages = const [],
    this.enableDnd = true,
    this.enableGrayscale = false,
    this.enableKillSwitch = false,
    this.pin,
  });

  factory PublicModeConfig.fromJson(Map<String, Object?> json) {
    return PublicModeConfig(
      timeoutMinutes: (json['timeoutMinutes'] as num?)?.toInt() ?? 10,
      hiddenTiles: (json['hiddenTiles'] as List?)?.map((e) => e.toString()).toList() ??
          const ['payment_qr', 'quick_texts', 'wireless_debugging'],
      blockedPackages:
          (json['blockedPackages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      enableDnd: json['enableDnd'] as bool? ?? true,
      enableGrayscale: json['enableGrayscale'] as bool? ?? false,
      enableKillSwitch: json['enableKillSwitch'] as bool? ?? false,
      pin: (json['pin'] as String?)?.takeIfNotEmpty,
    );
  }

  final int timeoutMinutes;
  final List<String> hiddenTiles;
  final List<String> blockedPackages;
  final bool enableDnd;
  final bool enableGrayscale;
  final bool enableKillSwitch;
  final String? pin;

  Map<String, Object?> toJson() => {
        'timeoutMinutes': timeoutMinutes,
        'hiddenTiles': hiddenTiles,
        'blockedPackages': blockedPackages,
        'enableDnd': enableDnd,
        'enableGrayscale': enableGrayscale,
        'enableKillSwitch': enableKillSwitch,
        'pin': pin,
      };

  PublicModeConfig copyWith({
    int? timeoutMinutes,
    List<String>? hiddenTiles,
    List<String>? blockedPackages,
    bool? enableDnd,
    bool? enableGrayscale,
    bool? enableKillSwitch,
    String? pin,
    bool clearPin = false,
  }) {
    return PublicModeConfig(
      timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
      hiddenTiles: hiddenTiles ?? this.hiddenTiles,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      enableDnd: enableDnd ?? this.enableDnd,
      enableGrayscale: enableGrayscale ?? this.enableGrayscale,
      enableKillSwitch: enableKillSwitch ?? this.enableKillSwitch,
      pin: clearPin ? null : (pin ?? this.pin),
    );
  }

  @override
  List<Object?> get props => [
        timeoutMinutes,
        hiddenTiles,
        blockedPackages,
        enableDnd,
        enableGrayscale,
        enableKillSwitch,
        pin,
      ];
}

extension on String {
  String? get takeIfNotEmpty => trim().isEmpty ? null : trim();
}

class PublicModeRepository {
  const PublicModeRepository(this._channel);

  final QsChannel _channel;

  Future<PublicModeConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.publicModeConfig);
    if (raw == null) return const PublicModeConfig();
    try {
      return PublicModeConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const PublicModeConfig();
    }
  }

  Future<void> saveConfig(PublicModeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.publicModeConfig, jsonEncode(config.toJson()));
  }

  Future<
      ({
        bool active,
        int endsAt,
        bool hasUsageAccess,
        bool canDrawOverlays,
        bool hasDndAccess,
      })> getState() => _channel.getPublicModeState();

  Future<bool> activate() => _channel.activatePublicMode();

  Future<bool> deactivate() => _channel.deactivatePublicMode();

  Future<bool> canDrawOverlays() => _channel.canDrawOverlays();

  Future<bool> openOverlayPermissionSettings() => _channel.openOverlayPermissionSettings();

  Future<bool> hasDndAccess() => _channel.hasDndAccess();

  Future<bool> openDndPermissionSettings() => _channel.openDndPermissionSettings();

  Future<bool> hasUsageAccess() => _channel.hasUsageAccess();

  Future<bool> openUsageAccessSettings() => _channel.openUsageAccessSettings();

  Future<List<({String package, String label, Uint8List icon})>> getLaunchableApps() =>
      _channel.getLaunchableApps();
}
