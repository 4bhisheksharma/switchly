import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';
import 'display_models.dart';

/// Grayscale and animation speed: the live system values plus the tile's speed cycle.
class DisplayRepository {
  const DisplayRepository(this._channel);

  final QsChannel _channel;

  Future<AnimationConfig> loadAnimationConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.animationConfig);
    if (raw == null) return AnimationConfig.defaults;
    try {
      return AnimationConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object catch (e) {
      debugPrint('DisplayRepository: invalid stored config, using defaults: $e');
      return AnimationConfig.defaults;
    }
  }

  Future<void> saveAnimationConfig(AnimationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.animationConfig, jsonEncode(config.toJson()));
  }

  Future<({bool grayscale, AnimationScales scales})> readLive() async {
    final raw = await _channel.getDisplayState();
    return (grayscale: raw.grayscale, scales: AnimationScales(raw.window, raw.transition, raw.animator));
  }

  /// Both return false if the system refused the change.
  Future<bool> setGrayscale(bool on) => _channel.setGrayscale(on);

  Future<bool> setAnimationSpeed(double speed) => _channel.setAnimationScale(speed);
}
