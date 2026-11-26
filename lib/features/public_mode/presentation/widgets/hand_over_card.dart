import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/router.dart';
import '../../../../core/platform/qs_channel.dart';
import '../../../../core/widgets/tile_icon.dart';
import '../../bloc/public_mode_bloc.dart';
import '../../data/public_mode_models.dart';
import 'public_mode_pin_dialogs.dart';

class HandOverCard extends StatefulWidget {
  const HandOverCard({super.key});

  @override
  State<HandOverCard> createState() => _HandOverCardState();
}

class _HandOverCardState extends State<HandOverCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final state = context.read<PublicModeBloc>().state;
        if (state.active && state.endsAt > 0) {
          setState(() {});
          if (state.remainingSeconds <= 0) {
            context.read<PublicModeBloc>().add(const PublicModeRefreshed());
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _promptActivate(BuildContext context, PublicModeState state) async {
    final bloc = context.read<PublicModeBloc>();
    final channel = context.read<QsChannel>();
    final repository = PublicModeRepository(channel);

    if (state.config.pin == null || state.config.pin!.isEmpty) {
      final created = await showPublicModePinSetupDialog(
        context,
        repository: repository,
        onSaved: (newPin, recoveryAnswer) {
          bloc.add(PublicModeConfigUpdated(
            state.config.copyWith(
              pin: newPin,
              recoveryAnswer: recoveryAnswer,
            ),
          ));
        },
      );
      if (!created) return;
    }

    bloc.add(const PublicModeActivateRequested());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.config.timeoutMinutes > 0
                ? 'Public Mode active for ${state.config.timeoutMinutes} min · Private apps locked'
                : 'Public Mode active · Private apps locked',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _promptExit(BuildContext context, PublicModeState state) async {
    final bloc = context.read<PublicModeBloc>();
    final channel = context.read<QsChannel>();
    final repository = PublicModeRepository(channel);

    if (state.config.pin != null && state.config.pin!.isNotEmpty) {
      await showPublicModePinVerifyDialog(
        context,
        expectedPin: state.config.pin!,
        recoveryAnswer: state.config.recoveryAnswer,
        endsAt: state.endsAt,
        repository: repository,
        onVerified: () async {
          bloc.add(const PublicModeDeactivateRequested());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Public Mode ended · Previous profile restored'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } else {
      bloc.add(const PublicModeDeactivateRequested());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Public Mode ended · Previous profile restored'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final state = context.watch<PublicModeBloc>().state;
    final isActive = state.active;

    if (isActive) {
      final timeLabel = state.endsAt > 0 ? state.formattedRemainingTime : 'Active until turned off';
      final blockedCount = state.config.blockedPackages.length;
      final hiddenCount = state.config.hiddenTiles.length;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.error.withValues(alpha: dark ? 0.12 : 0.06),
          border: Border.all(
            color: scheme.error.withValues(alpha: 0.4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Symbols.shield_person_rounded,
                    color: scheme.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Public Mode Active',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: scheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.endsAt > 0 ? timeLabel : 'Active',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$blockedCount private apps blocked · $hiddenCount tiles hidden',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Symbols.settings_rounded, size: 17),
                    label: const Text('Configure'),
                    onPressed: () => Navigator.of(context).pushNamed(AppRouter.publicMode),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    icon: const Icon(Symbols.lock_open_rounded, size: 17),
                    label: const Text('Exit & Restore'),
                    onPressed: () => _promptExit(context, state),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Inactive compact quick-action card
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const TileIcon(Symbols.shield_person_rounded, active: true, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lock private apps before handing over',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Configure Public Mode',
            icon: Icon(Symbols.tune_rounded, color: scheme.onSurfaceVariant, size: 20),
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.publicMode),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _promptActivate(context, state),
            child: const Text('Hand over'),
          ),
        ],
      ),
    );
  }
}
