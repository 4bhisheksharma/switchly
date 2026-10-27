import 'package:equatable/equatable.dart';

/// A DNS-over-TLS provider. Built-in ids are fixed; custom ones start with `custom_`.
class DnsProvider extends Equatable {
  const DnsProvider({required this.id, required this.name, required this.host, this.enabled = true});

  factory DnsProvider.fromJson(Map<String, Object?> json) => DnsProvider(
        id: json['id'] as String? ?? 'custom_${json['host']}',
        name: json['name'] as String? ?? '',
        host: json['host'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String host;
  final bool enabled;

  bool get isCustom => id.startsWith('custom_');

  /// One-line description for built-in providers.
  String? get tagline => _taglines[id];

  static const _taglines = {
    'adguard': 'Blocks ads and trackers',
    'cloudflare': 'Fast and privacy-focused',
    'google': 'Reliable public DNS',
    'quad9': 'Blocks malicious domains',
    'mullvad': 'No logging, no filtering',
  };

  DnsProvider copyWith({String? name, String? host, bool? enabled}) =>
      DnsProvider(id: id, name: name ?? this.name, host: host ?? this.host, enabled: enabled ?? this.enabled);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'host': host, 'enabled': enabled};

  @override
  List<Object?> get props => [id, name, host, enabled];
}

/// The tile's cycle. Mirrors `DnsConfig` in android/.../dns/PrivateDns.kt.
class DnsConfig extends Equatable {
  const DnsConfig({required this.includeOff, required this.includeAutomatic, required this.providers});

  factory DnsConfig.fromJson(Map<String, Object?> json) => DnsConfig(
        includeOff: json['includeOff'] as bool? ?? true,
        includeAutomatic: json['includeAutomatic'] as bool? ?? false,
        providers: [
          for (final p in json['providers'] as List? ?? const []) DnsProvider.fromJson(p as Map<String, Object?>),
        ],
      );

  /// Used until the user edits the cycle. Keep in sync with DEFAULT_CONFIG in PrivateDns.kt.
  static const defaults = DnsConfig(
    includeOff: true,
    includeAutomatic: false,
    providers: [
      DnsProvider(id: 'adguard', name: 'AdGuard', host: 'dns.adguard-dns.com'),
      DnsProvider(id: 'cloudflare', name: 'Cloudflare', host: 'one.one.one.one'),
      DnsProvider(id: 'google', name: 'Google', host: 'dns.google'),
      DnsProvider(id: 'quad9', name: 'Quad9', host: 'dns.quad9.net'),
      DnsProvider(id: 'mullvad', name: 'Mullvad', host: 'dns.mullvad.net', enabled: false),
    ],
  );

  /// The tile needs at least two states to be useful.
  static const minCycleLength = 2;

  final bool includeOff;
  final bool includeAutomatic;
  final List<DnsProvider> providers;

  int get cycleLength =>
      (includeOff ? 1 : 0) + (includeAutomatic ? 1 : 0) + providers.where((p) => p.enabled).length;

  bool get canRemoveFromCycle => cycleLength > minCycleLength;

  DnsProvider? providerForHost(String? host) {
    if (host == null) return null;
    for (final p in providers) {
      if (p.host.toLowerCase() == host.toLowerCase()) return p;
    }
    return null;
  }

  DnsConfig copyWith({bool? includeOff, bool? includeAutomatic, List<DnsProvider>? providers}) => DnsConfig(
        includeOff: includeOff ?? this.includeOff,
        includeAutomatic: includeAutomatic ?? this.includeAutomatic,
        providers: providers ?? this.providers,
      );

  Map<String, Object?> toJson() => {
        'includeOff': includeOff,
        'includeAutomatic': includeAutomatic,
        'providers': [for (final p in providers) p.toJson()],
      };

  @override
  List<Object?> get props => [includeOff, includeAutomatic, providers];
}

enum PrivateDnsMode {
  off('off'),
  automatic('opportunistic'),
  hostname('hostname');

  const PrivateDnsMode(this.raw);

  /// The value stored in Settings.Global `private_dns_mode`.
  final String raw;

  static PrivateDnsMode fromRaw(String raw) =>
      values.firstWhere((m) => m.raw == raw, orElse: () => PrivateDnsMode.automatic);
}

/// What the system is using right now.
class PrivateDnsState extends Equatable {
  const PrivateDnsState(this.mode, [this.host]);

  final PrivateDnsMode mode;

  /// Only meaningful when [mode] is [PrivateDnsMode.hostname].
  final String? host;

  bool get isEncrypted => mode == PrivateDnsMode.hostname;

  bool isProvider(DnsProvider provider) =>
      mode == PrivateDnsMode.hostname && host?.toLowerCase() == provider.host.toLowerCase();

  @override
  List<Object?> get props => [mode, mode == PrivateDnsMode.hostname ? host : null];
}

/// Strips schemes, paths and ports users often paste, e.g. `https://dns.example.com/dns-query`.
String normalizeHostname(String input) {
  var host = input.trim().toLowerCase();
  host = host.replaceFirst(RegExp(r'^[a-z]+://'), '');
  host = host.split('/').first.split(':').first;
  return host.endsWith('.') ? host.substring(0, host.length - 1) : host;
}

final _hostnamePattern = RegExp(r'^(?=.{1,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{0,61}[a-z0-9]$');

bool isValidHostname(String host) => _hostnamePattern.hasMatch(host);
