import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/platform/qs_channel.dart';
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
    final state = context.watch<PublicModeBloc>().state;
    final isActive = state.active;

    if (isActive) {
      final timeLabel = state.endsAt > 0 ? state.formattedRemainingTime : 'Active until turned off';
      final blockedCount = state.config.blockedPackages.length;
      final hiddenCount = state.config.hiddenTiles.length;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1013), Color(0xFF1E101D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Symbols.shield_person_rounded,
                    color: Color(0xFFFCA5A5),
                    size: 26,
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.endsAt > 0 ? timeLabel : 'Active',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFFECACA),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$blockedCount private apps blocked · $hiddenCount tiles hidden',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Symbols.settings_rounded, size: 18),
                    label: const Text('Configure'),
                    onPressed: () => Navigator.of(context).pushNamed(AppRouter.publicMode),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Symbols.lock_open_rounded, size: 18),
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

    // Inactive Hero Card
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerLow,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Symbols.shield_person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hand my phone over',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'One tap prepares your device before handing it to a friend, child, or colleague.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Configure Public Mode',
                icon: Icon(Symbols.tune_rounded, color: scheme.onSurfaceVariant, size: 22),
                onPressed: () => Navigator.of(context).pushNamed(AppRouter.publicMode),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Symbols.front_hand_rounded, size: 20),
                  label: const Text(
                    'Hand my phone over',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _promptActivate(context, state),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
