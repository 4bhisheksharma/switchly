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
        color: active ? colors.primary : colors.surfaceContainerHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        fill: active ? 1 : 0,
        color: active ? colors.onPrimary : colors.onSurfaceVariant,
      ),
    );
  }
}
