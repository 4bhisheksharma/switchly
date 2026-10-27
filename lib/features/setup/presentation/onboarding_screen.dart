import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/setup_bloc.dart';
import '../data/setup_repository.dart';

/// Walks the user through granting WRITE_SECURE_SETTINGS over ADB.
///
/// Shown by the app shell until the permission is granted. The permission is also
/// re-checked whenever the app returns to the foreground.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SetupBloc>().state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Set up Switchly')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Switchly changes system settings that normal apps can\'t. Android only '
            'allows this after a one-time permission grant from a computer over ADB. '
            'Nothing else is needed, and the app never goes online.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _Step(
            number: 1,
            title: 'Enable USB debugging',
            body: 'Settings → About phone → tap "Build number" 7 times, then turn on '
                'Developer options → USB debugging.',
            action: TextButton(
              onPressed: () => _openDeveloperOptions(context),
              child: const Text('Open Developer options'),
            ),
          ),
          _Step(
            number: 2,
            title: 'Run this command on your computer',
            body: 'Connect the phone with a USB cable, then run:',
            action: _CommandBox(command: state.adbCommand),
          ),
          _Step(
            number: 3,
            title: 'Come back here',
            body: 'Switchly checks automatically when you return to the app.',
            action: FilledButton.icon(
              onPressed: state.isChecking
                  ? null
                  : () => context.read<SetupBloc>().add(const SetupPermissionCheckRequested()),
              icon: state.isChecking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Check again'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeveloperOptions(BuildContext context) async {
    final opened = await context.read<SetupRepository>().openDeveloperOptions();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable Developer options first (step 1).')),
      );
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.action,
  });

  final int number;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text('$number')),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
                const SizedBox(height: 8),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: command));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Command copied')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
