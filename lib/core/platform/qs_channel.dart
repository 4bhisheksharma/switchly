import 'dart:async';

import 'package:flutter/services.dart';

/// Outcome of asking the system to add a tile (`StatusBarManager.requestAddTileService`).
enum AddTileResult { added, alreadyAdded, notAdded, unsupported, error }

/// System settings screens the app can open.
enum SystemPanel { internet, developerOptions }

class DeviceInfo {
  const DeviceInfo({required this.packageName, required this.sdkInt});

  final String packageName;
  final int sdkInt;

  /// The in-app "Add tile" prompt exists from Android 13 (API 33).
  bool get supportsAddTileRequest => sdkInt >= 33;
}

/// Typed wrapper around the `qs_toggles` MethodChannel.
///
/// Mirrors android/.../channel/QsTogglesChannel.kt; method names must match.
class QsChannel {
  QsChannel([this._channel = const MethodChannel('qs_toggles')]) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final _launchRoutes = StreamController<String>.broadcast();

  /// Routes requested by native code while the app is running (tile tap / long-press).
  Stream<String> get launchRoutes => _launchRoutes.stream;

  Future<bool> hasWriteSecureSettings() async =>
      await _channel.invokeMethod<bool>('hasWriteSecureSettings') ?? false;

  Future<DeviceInfo> getDeviceInfo() async {
    final info = await _channel.invokeMapMethod<String, Object?>('getDeviceInfo');
    return DeviceInfo(
      packageName: info!['packageName']! as String,
      sdkInt: info['sdkInt']! as int,
    );
  }

  /// The route that cold-started the app, if any. Returns it only once.
  Future<String?> takeLaunchRoute() => _channel.invokeMethod<String>('takeLaunchRoute');

  Future<AddTileResult> requestAddTile(String tileId) async {
    final result = await _channel.invokeMethod<String>('requestAddTile', {'tile': tileId});
    return switch (result) {
      'added' => AddTileResult.added,
      'already_added' => AddTileResult.alreadyAdded,
      'not_added' => AddTileResult.notAdded,
      'unsupported' => AddTileResult.unsupported,
      _ => AddTileResult.error,
    };
  }

  /// Returns false when the device has no screen for [panel].
  Future<bool> openSystemPanel(SystemPanel panel) async {
    final name = switch (panel) {
      SystemPanel.internet => 'internet',
      SystemPanel.developerOptions => 'developer_options',
    };
    return await _channel.invokeMethod<bool>('openSystemPanel', {'panel': name}) ?? false;
  }

  /// Raw Private DNS settings: `mode` is `off`, `opportunistic` or `hostname`.
  Future<({String mode, String? host})> getPrivateDns() async {
    final state = await _channel.invokeMapMethod<String, Object?>('getPrivateDns');
    return (mode: state!['mode']! as String, host: state['host'] as String?);
  }

  /// Returns false when the write was refused (usually a missing permission).
  Future<bool> setPrivateDns({required String mode, String? host}) async =>
      await _channel.invokeMethod<bool>('setPrivateDns', {'mode': mode, 'host': host}) ?? false;

  /// Runs `pm grant` through `su`. Returns true only if the permission is now held.
  Future<bool> grantWithRoot() async =>
      await _channel.invokeMethod<bool>('grantWithRoot') ?? false;

  /// Grayscale on/off and the three animation scales.
  Future<({bool grayscale, double window, double transition, double animator})> getDisplayState() async {
    final state = await _channel.invokeMapMethod<String, Object?>('getDisplayState');
    return (
      grayscale: state!['grayscale']! as bool,
      window: state['windowScale']! as double,
      transition: state['transitionScale']! as double,
      animator: state['animatorScale']! as double,
    );
  }

  Future<bool> setGrayscale(bool on) async =>
      await _channel.invokeMethod<bool>('setGrayscale', {'on': on}) ?? false;

  /// Sets window, transition and animator scales together.
  Future<bool> setAnimationScale(double scale) async =>
      await _channel.invokeMethod<bool>('setAnimationScale', {'scale': scale}) ?? false;

  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onLaunchRoute') {
      _launchRoutes.add(call.arguments as String);
    }
    return null;
  }

  void dispose() => _launchRoutes.close();
}
