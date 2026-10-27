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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? colors.primaryContainer : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: highlighted ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
