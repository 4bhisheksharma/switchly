import 'package:flutter/material.dart';

import 'status_pill.dart';
import 'tile_icon.dart';

/// Clean architectural status card at the top of a feature screen.
class HeroStatusCard extends StatelessWidget {
  const HeroStatusCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.active = false,
    this.busy = false,
    this.action,
  });

  final IconData icon;

  /// Small caption above [value], e.g. "Currently using".
  final String label;
  final String value;
  final String detail;
  final bool active;
  final bool busy;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: active
            ? colors.primary.withValues(alpha: dark ? 0.10 : 0.05)
            : colors.surfaceContainerLow,
        border: Border.all(
          color: active
              ? colors.primary.withValues(alpha: dark ? 0.42 : 0.32)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TileIcon(icon, active: active, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: active ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (busy)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                )
              else if (active)
                const StatusPill('Active', highlighted: true),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Align(
              key: ValueKey(value),
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
