import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';
import 'dns_models.dart';

/// Stores the tile cycle (read by the Kotlin tile) and reads/changes the live setting.
class DnsRepository {
  const DnsRepository(this._channel);

  final QsChannel _channel;

  Future<DnsConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.dnsConfig);
    if (raw == null) return DnsConfig.defaults;
    try {
      return DnsConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object catch (e) {
      debugPrint('DnsRepository: invalid stored config, using defaults: $e');
      return DnsConfig.defaults;
    }
  }

  Future<void> saveConfig(DnsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.dnsConfig, jsonEncode(config.toJson()));
  }

  Future<PrivateDnsState> readLiveState() async {
    final raw = await _channel.getPrivateDns();
    return PrivateDnsState(PrivateDnsMode.fromRaw(raw.mode), raw.host);
  }

  /// Returns false if the system refused the change.
  Future<bool> apply(PrivateDnsState target) =>
      _channel.setPrivateDns(mode: target.mode.raw, host: target.host);
}
