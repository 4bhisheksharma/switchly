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

  /// Grayscale on/off, the three animation scales and the font scale.
  Future<({bool grayscale, double window, double transition, double animator, double fontScale})>
      getDisplayState() async {
    final state = await _channel.invokeMapMethod<String, Object?>('getDisplayState');
    return (
      grayscale: state!['grayscale']! as bool,
      window: state['windowScale']! as double,
      transition: state['transitionScale']! as double,
      animator: state['animatorScale']! as double,
      fontScale: state['fontScale']! as double,
    );
  }

  Future<bool> setGrayscale(bool on) async =>
      await _channel.invokeMethod<bool>('setGrayscale', {'on': on}) ?? false;

  /// Sets window, transition and animator scales together.
  Future<bool> setAnimationScale(double scale) async =>
      await _channel.invokeMethod<bool>('setAnimationScale', {'scale': scale}) ?? false;

  Future<bool> setFontScale(double scale) async =>
      await _channel.invokeMethod<bool>('setFontScale', {'scale': scale}) ?? false;

  /// Whether Caffeine is on, its duration (0 = no limit) and end time (epoch ms, 0 = none).
  Future<({bool on, int? minutes, int endsAt})> getCaffeine() => _caffeine('getCaffeine');

  Future<({bool on, int? minutes, int endsAt})> startCaffeine(int minutes) =>
      _caffeine('startCaffeine', {'minutes': minutes});

  Future<({bool on, int? minutes, int endsAt})> stopCaffeine() => _caffeine('stopCaffeine');

  Future<({bool on, int? minutes, int endsAt})> _caffeine(String method, [Object? args]) async {
    final state = await _channel.invokeMapMethod<String, Object?>(method, args);
    return (on: state!['on']! as bool, minutes: state['minutes'] as int?, endsAt: state['endsAt']! as int);
  }

  /// Level (%), plug state, temperature (°C) and charging power (W); the last two may be null.
  Future<({int level, bool plugged, bool full, double? temperature, double? watts})> getBatteryInfo() async {
    final state = await _channel.invokeMapMethod<String, Object?>('getBatteryInfo');
    return (
      level: state!['level']! as int,
      plugged: state['plugged']! as bool,
      full: state['full']! as bool,
      temperature: state['temperature'] as double?,
      watts: state['watts'] as double?,
    );
  }

  /// Wireless debugging and kill switch state. [address] is `ip:port`, just the IP, or null.
  Future<
      ({
        bool wirelessSupported,
        bool wirelessDebugging,
        bool devOptions,
        String? address,
        bool killSwitch,
      })> getNetworkState() async {
    final state = await _channel.invokeMapMethod<String, Object?>('getNetworkState');
    return (
      wirelessSupported: state!['wirelessSupported']! as bool,
      wirelessDebugging: state['wirelessDebugging']! as bool,
      devOptions: state['devOptions']! as bool,
      address: state['address'] as String?,
      killSwitch: state['killSwitch']! as bool,
    );
  }

  Future<bool> setWirelessDebugging(bool on) async =>
      await _channel.invokeMethod<bool>('setWirelessDebugging', {'on': on}) ?? false;

  /// Shows Android's one-time VPN consent dialog if needed. False if declined or refused.
  Future<bool> startKillSwitch() async => await _channel.invokeMethod<bool>('startKillSwitch') ?? false;

  Future<bool> stopKillSwitch() async => await _channel.invokeMethod<bool>('stopKillSwitch') ?? false;

  /// Re-applies the exception list to a running kill switch.
  Future<bool> reloadKillSwitch() async => await _channel.invokeMethod<bool>('reloadKillSwitch') ?? false;

  /// Apps with a launcher icon, sorted by label. Icons are 96px PNGs.
  Future<List<({String package, String label, Uint8List icon})>> getLaunchableApps() async {
    final apps = await _channel.invokeListMethod<Map<Object?, Object?>>('getLaunchableApps') ?? const [];
    return [
      for (final app in apps)
        (package: app['package']! as String, label: app['label']! as String, icon: app['icon']! as Uint8List),
    ];
  }

  /// Opens the native QR scanner (asks for camera permission the first time).
  Future<void> openQrScanner() => _channel.invokeMethod<bool>('openQrScanner');

  Future<String?> getActiveProfile() => _channel.invokeMethod<String>('getActiveProfile');

  /// Returns false if any part of the profile was refused.
  Future<bool> applyProfile(String id) async =>
      await _channel.invokeMethod<bool>('applyProfile', {'id': id}) ?? false;

  Future<bool> restoreProfile() async => await _channel.invokeMethod<bool>('restoreProfile') ?? false;

  /// Runtime app version information directly from the Android package manager.
  Future<({String versionName, int versionCode})> getAppVersion() async {
    final info = await _channel.invokeMapMethod<String, Object?>('getAppVersion');
    return (
      versionName: info!['versionName']! as String,
      versionCode: (info['versionCode']! as num).toInt(),
    );
  }

  /// Whether the app is allowed to request package installations on Android 8.0+.
  Future<bool> canInstallPackages() async =>
      await _channel.invokeMethod<bool>('canInstallPackages') ?? true;

  /// Opens the system "Install unknown apps" settings screen for Switchly.
  Future<bool> openInstallPermissionSettings() async =>
      await _channel.invokeMethod<bool>('openInstallPermissionSettings') ?? false;

  /// Prompts the Android package installer to install or update the given APK file.
  Future<bool> installApk(String path) async =>
      await _channel.invokeMethod<bool>('installApk', {'path': path}) ?? false;

  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onLaunchRoute') {
      _launchRoutes.add(call.arguments as String);
    }
    return null;
  }

  void dispose() => _launchRoutes.close();
}
