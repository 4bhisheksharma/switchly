import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';

/// Durations offered for Caffeine, in minutes. 0 means no time limit.
const caffeineDurations = <int>[5, 10, 15, 30, 60, 120, 0];

String durationLabel(int minutes) => switch (minutes) {
  0 => 'No limit',
  60 => '1 hour',
  _ when minutes % 60 == 0 => '${minutes ~/ 60} hours',
  _ => '$minutes min',
};

/// The Caffeine tile's duration cycle. Mirrors `Caffeine.config` in Kotlin.
class CaffeineConfig extends Equatable {
  const CaffeineConfig({required this.minutes, required this.stopOnLock});

  factory CaffeineConfig.fromJson(Map<String, Object?> json) => CaffeineConfig(
    minutes: [for (final m in json['minutes'] as List? ?? const []) m as int],
    stopOnLock: json['stopOnLock'] as bool? ?? true,
  );

  /// Used until the user edits it. Keep in sync with DEFAULT_MINUTES in Caffeine.kt.
  static const defaults = CaffeineConfig(minutes: [5, 15, 30, 60, 0], stopOnLock: true);

  /// In tap order: ascending, with "no limit" last.
  final List<int> minutes;

  /// Turn off when the screen turns off (power button or lock).
  final bool stopOnLock;

  bool includes(int m) => minutes.contains(m);

  bool get canRemove => minutes.length > 1;

  CaffeineConfig toggled(int m) => CaffeineConfig(
    minutes: includes(m) ? minutes.where((x) => x != m).toList() : _sorted([...minutes, m]),
    stopOnLock: stopOnLock,
  );

  CaffeineConfig withStopOnLock(bool value) => CaffeineConfig(minutes: minutes, stopOnLock: value);

  static List<int> _sorted(List<int> list) => list..sort((a, b) => a == 0 ? 1 : (b == 0 ? -1 : a.compareTo(b)));

  Map<String, Object?> toJson() => {'minutes': minutes, 'stopOnLock': stopOnLock};

  @override
  List<Object?> get props => [minutes, stopOnLock];
}

/// A running (or stopped) Caffeine session.
class CaffeineStatus extends Equatable {
  const CaffeineStatus({this.on = false, this.minutes, this.endsAt});

  final bool on;
  final int? minutes;

  /// Null when off or when there is no time limit.
  final DateTime? endsAt;

  @override
  List<Object?> get props => [on, minutes, endsAt];
}

class BatteryStatus extends Equatable {
  const BatteryStatus({required this.level, required this.plugged, required this.full, this.temperature, this.watts});

  final int level;
  final bool plugged;
  final bool full;
  final double? temperature;
  final double? watts;

  @override
  List<Object?> get props => [level, plugged, full, temperature, watts];
}

class PowerRepository {
  const PowerRepository(this._channel);

  final QsChannel _channel;

  Future<CaffeineConfig> loadCaffeineConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.caffeineConfig);
    if (raw == null) return CaffeineConfig.defaults;
    try {
      return CaffeineConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object catch (e) {
      debugPrint('PowerRepository: invalid stored caffeine config, using defaults: $e');
      return CaffeineConfig.defaults;
    }
  }

  Future<void> saveCaffeineConfig(CaffeineConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.caffeineConfig, jsonEncode(config.toJson()));
  }

  Future<CaffeineStatus> caffeine() async => _status(await _channel.getCaffeine());

  Future<CaffeineStatus> startCaffeine(int minutes) async => _status(await _channel.startCaffeine(minutes));

  Future<CaffeineStatus> stopCaffeine() async => _status(await _channel.stopCaffeine());

  Future<BatteryStatus> battery() async {
    final raw = await _channel.getBatteryInfo();
    return BatteryStatus(
      level: raw.level,
      plugged: raw.plugged,
      full: raw.full,
      temperature: raw.temperature,
      watts: raw.watts,
    );
  }

  static CaffeineStatus _status(({bool on, int? minutes, int endsAt}) raw) => CaffeineStatus(
    on: raw.on,
    minutes: raw.minutes,
    endsAt: raw.on && raw.endsAt > 0 ? DateTime.fromMillisecondsSinceEpoch(raw.endsAt) : null,
  );
}
