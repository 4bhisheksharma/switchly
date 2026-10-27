part of 'network_bloc.dart';

sealed class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object?> get props => [];
}

final class NetworkStarted extends NetworkEvent {
  const NetworkStarted();
}

/// Re-reads live state (app resumed, or a tile changed it).
final class NetworkRefreshed extends NetworkEvent {
  const NetworkRefreshed();
}

final class WirelessDebuggingSet extends NetworkEvent {
  const WirelessDebuggingSet(this.on);

  final bool on;

  @override
  List<Object?> get props => [on];
}

/// Turning on may show Android's one-time VPN consent dialog.
final class KillSwitchSet extends NetworkEvent {
  const KillSwitchSet(this.on);

  final bool on;

  @override
  List<Object?> get props => [on];
}

/// Replaces the list of apps that stay online while the kill switch is on.
final class AllowedAppsChanged extends NetworkEvent {
  const AllowedAppsChanged(this.packages);

  final List<String> packages;

  @override
  List<Object?> get props => [packages];
}

/// Loads installed apps once, for the exception picker.
final class InstalledAppsRequested extends NetworkEvent {
  const InstalledAppsRequested();
}
