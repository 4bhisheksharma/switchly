import 'package:flutter/material.dart';

/// Compact label badge, e.g. "Active", "Recommended", "On".
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primary.withValues(alpha: dark ? 0.16 : 0.10)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? colors.primary.withValues(alpha: 0.25)
              : colors.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: highlighted ? colors.primary : colors.onSurfaceVariant,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}
