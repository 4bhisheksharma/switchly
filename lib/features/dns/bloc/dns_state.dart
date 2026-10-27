part of 'dns_bloc.dart';

enum DnsStatus { loading, ready }

final class DnsState extends Equatable {
  const DnsState({
    this.status = DnsStatus.loading,
    this.config = DnsConfig.defaults,
    this.live,
    this.applying = false,
    this.applyFailures = 0,
  });

  final DnsStatus status;
  final DnsConfig config;

  /// Null until read, or when not running on Android.
  final PrivateDnsState? live;
  final bool applying;

  /// Incremented on each refused change, so the UI can react once per failure.
  final int applyFailures;

  /// Human-readable name of what the system is using now.
  String get liveLabel => switch (live?.mode) {
        null => '—',
        PrivateDnsMode.off => 'Off',
        PrivateDnsMode.automatic => 'Automatic',
        PrivateDnsMode.hostname => config.providerForHost(live!.host)?.name ?? live!.host ?? 'Custom',
      };

  DnsState copyWith({
    DnsStatus? status,
    DnsConfig? config,
    PrivateDnsState? live,
    bool? applying,
    int? applyFailures,
  }) {
    return DnsState(
      status: status ?? this.status,
      config: config ?? this.config,
      live: live ?? this.live,
      applying: applying ?? this.applying,
      applyFailures: applyFailures ?? this.applyFailures,
    );
  }

  @override
  List<Object?> get props => [status, config, live, applying, applyFailures];
}
