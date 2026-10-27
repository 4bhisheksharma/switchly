part of 'network_bloc.dart';

final class NetworkState extends Equatable {
  const NetworkState({
    this.status,
    this.allowedApps = const [],
    this.installedApps,
    this.killSwitchBusy = false,
    this.failures = 0,
  });

  /// Null until read, or when not running on Android.
  final NetworkStatus? status;

  /// Packages that stay online while the kill switch is on.
  final List<String> allowedApps;

  /// Null until [InstalledAppsRequested] finishes.
  final List<InstalledApp>? installedApps;
  final bool killSwitchBusy;

  /// Incremented on each refused change, so the UI can react once per failure.
  final int failures;

  bool get killSwitchOn => status?.killSwitch ?? false;

  InstalledApp? appFor(String package) => installedApps?.where((a) => a.package == package).firstOrNull;

  NetworkState copyWith({
    NetworkStatus? status,
    List<String>? allowedApps,
    List<InstalledApp>? installedApps,
    bool? killSwitchBusy,
    int? failures,
  }) {
    return NetworkState(
      status: status ?? this.status,
      allowedApps: allowedApps ?? this.allowedApps,
      installedApps: installedApps ?? this.installedApps,
      killSwitchBusy: killSwitchBusy ?? this.killSwitchBusy,
      failures: failures ?? this.failures,
    );
  }

  @override
  List<Object?> get props => [status, allowedApps, installedApps, killSwitchBusy, failures];
}
