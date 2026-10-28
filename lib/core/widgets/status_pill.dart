import 'package:flutter/material.dart';

/// Compact rounded label, e.g. "Active", "Recommended", "Soon".
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: highlighted ? colors.primary.withValues(alpha: 0.12) : colors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: highlighted ? colors.primary.withValues(alpha: 0.3) : colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: highlighted ? colors.primary : colors.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
