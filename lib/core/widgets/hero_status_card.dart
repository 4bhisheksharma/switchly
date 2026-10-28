import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Large status card at the top of a tile screen. Uses the brand gradient when [active].
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
    final onCard = active ? Colors.white : colors.onSurface;
    final onCardMuted = active ? Colors.white.withValues(alpha: 0.85) : colors.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: active ? null : colors.surfaceContainerLow,
        border: Border.all(
          color: active ? colors.primary.withValues(alpha: 0.3) : colors.outlineVariant.withValues(alpha: 0.65),
        ),
        gradient: active ? AppTheme.brandGradient : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.18) : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  fill: active ? 1 : 0,
                  color: active ? Colors.white : colors.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const Spacer(),
              if (busy)
                SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: onCard)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onCardMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(value, key: ValueKey(value), style: theme.textTheme.headlineMedium?.copyWith(color: onCard)),
          ),
          const SizedBox(height: 4),
          Text(detail, style: theme.textTheme.bodyMedium?.copyWith(color: onCardMuted)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
