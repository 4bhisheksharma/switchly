import 'package:equatable/equatable.dart';

import '../../../core/platform/qs_channel.dart';

/// Live state of the network tiles.
class NetworkStatus extends Equatable {
  const NetworkStatus({
    required this.wirelessSupported,
    required this.wirelessDebugging,
    required this.devOptions,
    required this.address,
  });

  final bool wirelessSupported;
  final bool wirelessDebugging;
  final bool devOptions;

  /// `ip:port`, just the IP when the port isn't readable, or null without Wi-Fi.
  final String? address;

  bool get hasPort => address?.contains(':') ?? false;

  @override
  List<Object?> get props => [wirelessSupported, wirelessDebugging, devOptions, address];
}

/// Wireless debugging tile repository.
class NetworkRepository {
  const NetworkRepository(this._channel);

  final QsChannel _channel;

  Future<NetworkStatus> readStatus() async {
    final s = await _channel.getNetworkState();
    return NetworkStatus(
      wirelessSupported: s.wirelessSupported,
      wirelessDebugging: s.wirelessDebugging,
      devOptions: s.devOptions,
      address: s.address,
    );
  }

  Future<bool> setWirelessDebugging(bool on) => _channel.setWirelessDebugging(on);
}
