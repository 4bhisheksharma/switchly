import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A Quick Settings tile. [id] must match `TileRegistry` in Kotlin for available tiles.
class TileDefinition {
  const TileDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.available = true,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// False for tiles on the roadmap that aren't built yet.
  final bool available;
}

const privateDnsTile = TileDefinition(
  id: 'private_dns',
  name: 'Private DNS',
  description: 'Cycle between encrypted DNS providers.',
  icon: Symbols.dns_rounded,
);

const tileCatalog = <TileDefinition>[
  privateDnsTile,
  TileDefinition(
    id: 'grayscale',
    name: 'Grayscale',
    description: 'A monochrome screen to cut distraction.',
    icon: Symbols.contrast_rounded,
    available: false,
  ),
  TileDefinition(
    id: 'wireless_debugging',
    name: 'Wireless debugging',
    description: 'ADB over Wi-Fi in one tap.',
    icon: Symbols.developer_mode_rounded,
    available: false,
  ),
  TileDefinition(
    id: 'animation_speed',
    name: 'Animation speed',
    description: 'Switch between 0×, 0.5× and 1×.',
    icon: Symbols.speed_rounded,
    available: false,
  ),
  TileDefinition(
    id: 'kill_switch',
    name: 'Internet kill switch',
    description: 'Block all traffic instantly.',
    icon: Symbols.vpn_lock_rounded,
    available: false,
  ),
  TileDefinition(
    id: 'profiles',
    name: 'Profiles',
    description: 'Apply a bundle of settings at once.',
    icon: Symbols.tune_rounded,
    available: false,
  ),
];
