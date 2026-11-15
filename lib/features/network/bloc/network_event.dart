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
