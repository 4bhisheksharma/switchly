import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A Quick Settings tile. [id] must match `TileRegistry` in Kotlin.
class TileDefinition {
  const TileDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
}

const privateDnsTile = TileDefinition(
  id: 'private_dns',
  name: 'Private DNS',
  description: 'Cycle between encrypted DNS providers.',
  icon: Symbols.dns_rounded,
);

const killSwitchTile = TileDefinition(
  id: 'kill_switch',
  name: 'Internet kill switch',
  description: 'Block all traffic instantly.',
  icon: Symbols.public_off_rounded,
);

const wirelessDebuggingTile = TileDefinition(
  id: 'wireless_debugging',
  name: 'Wireless debugging',
  description: 'ADB over Wi-Fi in one tap.',
  icon: Symbols.developer_mode_rounded,
);

const grayscaleTile = TileDefinition(
  id: 'grayscale',
  name: 'Grayscale',
  description: 'A monochrome screen to cut distraction.',
  icon: Symbols.contrast_rounded,
);

const animationSpeedTile = TileDefinition(
  id: 'animation_speed',
  name: 'Animation speed',
  description: 'Cycle through animation speeds.',
  icon: Symbols.speed_rounded,
);

const quickTextsTile = TileDefinition(
  id: 'quick_texts',
  name: 'Quick texts',
  description: 'Copy saved snippets from anywhere.',
  icon: Symbols.content_paste_rounded,
);

const profilesTile = TileDefinition(
  id: 'profiles',
  name: 'Profiles',
  description: 'Apply a bundle of settings at once.',
  icon: Symbols.tune_rounded,
);
