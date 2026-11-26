import 'package:flutter/material.dart';

/// Rounded-square icon badge that gently tints with the accent colour when [active].
class TileIcon extends StatelessWidget {
  const TileIcon(this.icon, {super.key, this.active = false, this.size = 42});

  final IconData icon;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active
            ? colors.primary.withValues(alpha: dark ? 0.16 : 0.10)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(
          color: active
              ? colors.primary.withValues(alpha: dark ? 0.35 : 0.25)
              : colors.outlineVariant.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        fill: active ? 1 : 0,
        color: active ? colors.primary : colors.onSurfaceVariant,
      ),
    );
  }
}
