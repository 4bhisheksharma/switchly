import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../bloc/setup_bloc.dart';
import '../data/setup_repository.dart';

bool _sheetOpen = false;

/// Shows the one-time WRITE_SECURE_SETTINGS setup. Safe to call repeatedly.
///
/// The sheet watches [SetupBloc], so it flips to a success state by itself once the
/// permission is detected (the app re-checks whenever it returns to the foreground).
Future<void> showPermissionSheet(BuildContext context) async {
  if (_sheetOpen) return;
  _sheetOpen = true;
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const PermissionSheet(),
    );
  } finally {
    _sheetOpen = false;
  }
}

class PermissionSheet extends StatelessWidget {
  const PermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final granted = context.select((SetupBloc bloc) => bloc.state.hasPermission);
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: granted ? const _GrantedView() : const _SetupView(),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<SetupBloc>().state;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileIcon(Symbols.key_rounded, active: true, size: 56),
          const SizedBox(height: 20),
          Text('One-time setup', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Android only lets apps change settings like Private DNS after a special '
            'permission is granted once. It stays granted through updates and reboots.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _MethodCard(
            icon: Symbols.computer_rounded,
            title: 'Use a computer',
            badge: 'Recommended',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NumberedLine(
                  number: 1,
                  text: 'Turn on USB debugging in Developer options.',
                  action: TextButton(
                    onPressed: () => context.read<SetupRepository>().openDeveloperOptions(),
                    child: const Text('Open'),
                  ),
                ),
                const _NumberedLine(number: 2, text: 'Connect your phone and run:'),
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 12),
                  child: _CommandBox(command: state.adbCommand),
                ),
                const _NumberedLine(number: 3, text: 'Come back here. Switchly detects it automatically.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _MethodCard(
            icon: Symbols.bolt_rounded,
            title: 'Rooted device',
            child: _RootGrant(),
          ),
          const SizedBox(height: 20),
          _WaitingRow(checking: state.isChecking),
        ],
      ),
    );
  }
}

class _GrantedView extends StatelessWidget {
  const _GrantedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: const TileIcon(Symbols.check_rounded, active: true, size: 80),
          ),
          const SizedBox(height: 24),
          Text("You're all set", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Your tiles can now change system settings.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.icon, required this.title, required this.child, this.badge});

  final IconData icon;
  final String title;
  final String? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (badge != null) StatusPill(badge!, highlighted: true),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.number, required this.text, this.action});

  final int number;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
            child: Text('$number', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ?action,
        ],
      ),
    );
  }
}

class _CommandBox extends StatefulWidget {
  const _CommandBox({required this.command});

  final String command;

  @override
  State<_CommandBox> createState() => _CommandBoxState();
}

class _CommandBoxState extends State<_CommandBox> {
  bool _copied = false;
  Timer? _reset;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.command));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _copy,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.command,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: colors.onSurface),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _copied ? Symbols.check_rounded : Symbols.content_copy_rounded,
                  key: ValueKey(_copied),
                  size: 20,
                  color: _copied ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RootGrant extends StatefulWidget {
  const _RootGrant();

  @override
  State<_RootGrant> createState() => _RootGrantState();
}

class _RootGrantState extends State<_RootGrant> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _grant() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bloc = context.read<SetupBloc>();
    final granted = await context.read<SetupRepository>().grantWithRoot();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !granted;
    });
    if (granted) bloc.add(const SetupPermissionCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _failed
              ? "Root access wasn't granted. Allow Switchly in your root manager and try again."
              : 'Grant instantly through your root manager. No computer needed.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _failed ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _busy ? null : _grant,
          icon: _busy
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Symbols.bolt_rounded, size: 18),
          label: const Text('Grant with root'),
        ),
      ],
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({required this.checking});

  final bool checking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Waiting for permission…',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: checking ? null : () => context.read<SetupBloc>().add(const SetupPermissionCheckRequested()),
          child: const Text('Check again'),
        ),
      ],
    );
  }
}
