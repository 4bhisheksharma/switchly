import 'package:flutter/material.dart';

/// A Quick Settings tile the app ships. [id] must match `TileRegistry` in Kotlin.
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

const tileCatalog = <TileDefinition>[
  TileDefinition(
    id: 'private_dns',
    name: 'Private DNS',
    description: 'Cycle between Off and your DNS-over-TLS providers.',
    icon: Icons.dns_outlined,
  ),
];
