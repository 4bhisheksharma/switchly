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

  /// Whether Switchly has PACKAGE_USAGE_STATS permission to read app screen times.
  Future<bool> hasUsageAccess() async =>
      await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  /// Opens the system Usage Access settings screen for Switchly.
  Future<bool> openUsageAccessSettings() async =>
      await _channel.invokeMethod<bool>('openUsageAccessSettings') ?? false;

  /// Gets today's foreground screen time calculated directly in native Kotlin.
  Future<({int millis, String formatted})> getAppScreenTime(String packageName) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getAppScreenTime',
      {'packageName': packageName},
    );
    return (
      millis: (result?['millis'] as num?)?.toInt() ?? 0,
      formatted: (result?['formatted'] as String?) ?? '0m',
    );
  }

  /// Map of packageName to foregroundMillis today across all installed apps.
  Future<Map<String, int>> getTodayUsageStats() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('getTodayUsageStats');
    if (raw == null) return const {};
    return raw.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  /// Triggers a refresh for the AppScreenTimeTile.
  Future<bool> refreshAppScreenTimeTile() async =>
      await _channel.invokeMethod<bool>('refreshAppScreenTimeTile') ?? false;

  /// Gets current state and permissions for Public Mode.
  Future<
      ({
        bool active,
        int endsAt,
        bool hasUsageAccess,
        bool canDrawOverlays,
        bool hasDndAccess,
        bool isXiaomiDevice,
        bool hasMiuiPopupPermission,
        bool isIgnoringBattery,
      })> getPublicModeState() async {
    final state = await _channel.invokeMapMethod<String, Object?>('getPublicModeState');
    return (
      active: state?['active'] as bool? ?? false,
      endsAt: (state?['endsAt'] as num?)?.toInt() ?? 0,
      hasUsageAccess: state?['hasUsageAccess'] as bool? ?? false,
      canDrawOverlays: state?['canDrawOverlays'] as bool? ?? false,
      hasDndAccess: state?['hasDndAccess'] as bool? ?? false,
      isXiaomiDevice: state?['isXiaomiDevice'] as bool? ?? false,
      hasMiuiPopupPermission: state?['hasMiuiPopupPermission'] as bool? ?? true,
      isIgnoringBattery: state?['isIgnoringBattery'] as bool? ?? true,
    );
  }

  /// Opens Xiaomi/Redmi/POCO MIUI permissions editor directly for Switchly.
  Future<bool> openMiuiPermissions() async =>
      await _channel.invokeMethod<bool>('openMiuiPermissions') ?? false;

  /// Opens OEM autostart configuration for Xiaomi, Oppo, Vivo, Huawei, etc.
  Future<bool> openAutostartSettings() async =>
      await _channel.invokeMethod<bool>('openAutostartSettings') ?? false;

  /// Whether app is exempt from aggressive battery optimization killers.
  Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;

  /// Prompts system to ignore battery optimizations for reliable background service execution.
  Future<bool> requestIgnoreBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations') ?? false;

  /// Activates Public Mode natively (starts Foreground Service, monitors apps, applies protection).
  Future<bool> activatePublicMode() async =>
      await _channel.invokeMethod<bool>('activatePublicMode') ?? false;

  /// Deactivates Public Mode and restores previous profile and settings.
  Future<bool> deactivatePublicMode() async =>
      await _channel.invokeMethod<bool>('deactivatePublicMode') ?? false;

  /// Whether Switchly has permission to display over other apps (SYSTEM_ALERT_WINDOW).
  Future<bool> canDrawOverlays() async =>
      await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;

  /// Directs user to Android's Display Over Other Apps settings screen for Switchly.
  Future<bool> openOverlayPermissionSettings() async =>
      await _channel.invokeMethod<bool>('openOverlayPermissionSettings') ?? false;

  /// Whether Switchly has Do Not Disturb / Notification Policy access.
  Future<bool> hasDndAccess() async =>
      await _channel.invokeMethod<bool>('hasDndAccess') ?? false;

  /// Directs user to Android's Do Not Disturb access settings screen.
  Future<bool> openDndPermissionSettings() async =>
      await _channel.invokeMethod<bool>('openDndPermissionSettings') ?? false;

  /// Checks whether Android device has a secure lock screen (PIN, pattern, password or biometric) set.
  Future<bool> isDeviceSecure() async =>
      await _channel.invokeMethod<bool>('isDeviceSecure') ?? false;

  /// Prompts for Android device lock (fingerprint, face, PIN or pattern) via KeyguardManager.
  Future<bool> authenticateDeviceOwner() async =>
      await _channel.invokeMethod<bool>('authenticateDeviceOwner') ?? false;


  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onLaunchRoute') {
      _launchRoutes.add(call.arguments as String);
    }
    return null;
  }

  void dispose() => _launchRoutes.close();
}
