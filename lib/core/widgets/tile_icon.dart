import 'package:flutter/material.dart';

/// Rounded-square icon badge that fills with the accent colour when [active].
class TileIcon extends StatelessWidget {
  const TileIcon(this.icon, {super.key, this.active = false, this.size = 44});

  final IconData icon;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        fill: active ? 1 : 0,
        color: active ? colors.onPrimary : colors.onSurfaceVariant,
      ),
    );
  }
}
