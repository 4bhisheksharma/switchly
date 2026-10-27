import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';
import '../../display/data/display_models.dart';
import '../../dns/data/dns_models.dart';

/// Icons a profile can use, by stored key.
const profileIcons = <String, IconData>{
  'focus': Symbols.center_focus_strong_rounded,
  'night': Symbols.bedtime_rounded,
  'work': Symbols.work_rounded,
  'code': Symbols.code_rounded,
  'battery': Symbols.battery_saver_rounded,
  'study': Symbols.school_rounded,
  'travel': Symbols.flight_rounded,
  'calm': Symbols.self_improvement_rounded,
  'game': Symbols.sports_esports_rounded,
  'coffee': Symbols.coffee_rounded,
};

/// A named bundle of settings. Every setting is optional: null means "don't change".
/// Mirrors `Profile` in android/.../profiles/Profiles.kt.
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    this.icon = 'focus',
    this.dns,
    this.grayscale,
    this.animationSpeed,
    this.wirelessDebugging,
    this.killSwitch,
  });

  factory Profile.fromJson(Map<String, Object?> json) {
    final dns = json['dns'] as Map<String, Object?>?;
    return Profile(
      id: json['id']! as String,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'focus',
      dns: dns == null ? null : PrivateDnsState(PrivateDnsMode.fromRaw(dns['mode']! as String), dns['host'] as String?),
      grayscale: json['grayscale'] as bool?,
      animationSpeed: (json['animationSpeed'] as num?)?.toDouble(),
      wirelessDebugging: json['wirelessDebugging'] as bool?,
      killSwitch: json['killSwitch'] as bool?,
    );
  }

  final String id;
  final String name;
  final String icon;
  final PrivateDnsState? dns;
  final bool? grayscale;
  final double? animationSpeed;
  final bool? wirelessDebugging;
  final bool? killSwitch;

  IconData get iconData => profileIcons[icon] ?? Symbols.tune_rounded;

  bool get changesNothing =>
      dns == null && grayscale == null && animationSpeed == null && wirelessDebugging == null && killSwitch == null;

  /// Short descriptions of each change, e.g. "DNS: AdGuard", "Grayscale on".
  List<String> summary(DnsConfig dnsConfig) => [
        if (dns case final d?)
          'DNS: ${switch (d.mode) {
            PrivateDnsMode.off => 'Off',
            PrivateDnsMode.automatic => 'Automatic',
            PrivateDnsMode.hostname => dnsConfig.providerForHost(d.host)?.name ?? d.host ?? '',
          }}',
        if (grayscale case final g?) g ? 'Grayscale on' : 'Grayscale off',
        if (animationSpeed case final s?) sameSpeed(s, 0) ? 'No animations' : 'Animations ${speedLabel(s)}',
        if (wirelessDebugging case final w?) w ? 'Wireless debugging on' : 'Wireless debugging off',
        if (killSwitch case final k?) k ? 'Internet blocked' : 'Internet on',
      ];

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'dns': dns == null ? null : {'mode': dns!.mode.raw, 'host': dns!.host},
        'grayscale': grayscale,
        'animationSpeed': animationSpeed,
        'wirelessDebugging': wirelessDebugging,
        'killSwitch': killSwitch,
      };

  @override
  List<Object?> get props => [id, name, icon, dns, grayscale, animationSpeed, wirelessDebugging, killSwitch];
}

/// Starting points offered when the user has no profiles yet.
List<Profile> profileTemplates() {
  final seed = DateTime.now().microsecondsSinceEpoch;
  return [
    Profile(
      id: 'p$seed-focus',
      name: 'Focus',
      icon: 'focus',
      grayscale: true,
      animationSpeed: 0.5,
      dns: const PrivateDnsState(PrivateDnsMode.hostname, 'dns.adguard-dns.com'),
    ),
    Profile(id: 'p$seed-night', name: 'Wind down', icon: 'night', grayscale: true),
    Profile(id: 'p$seed-dev', name: 'Developer', icon: 'code', wirelessDebugging: true, animationSpeed: 0.5),
    Profile(id: 'p$seed-offline', name: 'Offline', icon: 'calm', killSwitch: true),
  ];
}

/// Stores profiles where the tile reads them; applying happens natively.
class ProfilesRepository {
  const ProfilesRepository(this._channel);

  final QsChannel _channel;

  Future<List<Profile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.profiles);
    if (raw == null) return const [];
    try {
      return [for (final p in jsonDecode(raw) as List) Profile.fromJson(p as Map<String, Object?>)];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<Profile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.profiles, jsonEncode([for (final p in profiles) p.toJson()]));
  }

  Future<String?> activeId() => _channel.getActiveProfile();

  /// The profile must be saved first: the native side reads it from storage.
  Future<bool> apply(String id) => _channel.applyProfile(id);

  Future<bool> restore() => _channel.restoreProfile();
}
