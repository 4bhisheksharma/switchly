import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../setup/presentation/add_tiles.dart';

/// Manage the Screenshot Quick Settings tile and Accessibility Service setup.
class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> with WidgetsBindingObserver {
  bool _serviceEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final channel = context.read<QsChannel>();
    final enabled = await channel.isAccessibilityServiceEnabled();
    if (!mounted) return;
    setState(() {
      _serviceEnabled = enabled;
    });
  }

  Future<void> _openSettings() async {
    HapticFeedback.selectionClick();
    final channel = context.read<QsChannel>();
    await channel.openAccessibilitySettings();
  }

  Future<void> _testScreenshot() async {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Capturing screenshot in 1 second...'),
        duration: Duration(milliseconds: 1500),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    final channel = context.read<QsChannel>();
    await channel.takeScreenshot();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Take screenshot')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList.list(
              children: [
                HeroStatusCard(
                  icon: Symbols.screenshot_monitor_rounded,
                  label: 'Quick Settings Tile',
                  value: _serviceEnabled ? 'Ready to capture' : 'Setup required',
                  detail: _serviceEnabled
                      ? 'The Screenshot tile is active. Pull down your notification shade from any screen and tap to capture.'
                      : 'Android requires the Switchly Accessibility shortcut to allow the Quick Settings tile to take screenshots.',
                  active: _serviceEnabled,
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (!_serviceEnabled)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          onPressed: _openSettings,
                          icon: const Icon(Symbols.settings_accessibility_rounded, size: 20),
                          label: const Text('Enable Shortcut'),
                        )
                      else ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4F46E5),
                          ),
                          onPressed: _testScreenshot,
                          icon: const Icon(Symbols.screenshot_rounded, size: 20),
                          label: const Text('Test Capture'),
                        ),
                        if (canRequestAddTile(context))
                          const AddTileButton(screenshotTile, onGradient: true),
                      ],
                    ],
                  ),
                ),
                if (!_serviceEnabled) ...[
                  const SectionHeader(
                    'Setup instructions',
                    subtitle: 'One-time permission required by Android',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StepRow(
                            step: '1',
                            title: 'Open Accessibility Settings',
                            desc: 'Tap the "Enable Shortcut" button above or open your phone Settings → Accessibility.',
                          ),
                          const Divider(height: 24),
                          _StepRow(
                            step: '2',
                            title: 'Find Switchly Screenshot Service',
                            desc: 'Look under Downloaded Apps or Installed Services for "Switchly Screenshot Service".',
                          ),
                          const Divider(height: 24),
                          _StepRow(
                            step: '3',
                            title: 'Turn On',
                            desc: 'Toggle the switch to allow Switchly to perform the screenshot global action.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SectionHeader(
                  'How it works',
                  subtitle: 'Fast, hardware-friendly screenshot capture',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureRow(
                          icon: Symbols.swipe_down_rounded,
                          title: 'Capture from anywhere',
                          desc: 'Pull down Quick Settings over any app, game, or browser and tap to capture instantly without awkwardly pressing physical buttons.',
                        ),
                        const Divider(height: 24),
                        _FeatureRow(
                          icon: Symbols.visibility_off_rounded,
                          title: 'Automatic shade dismissal',
                          desc: 'The tile automatically collapses the notification shade before taking the snapshot so your captured image is completely clean.',
                        ),
                        const Divider(height: 24),
                        _FeatureRow(
                          icon: Symbols.photo_library_rounded,
                          title: 'Native Android screenshots',
                          desc: 'Uses Android\'s built-in screenshot framework. Supports instant markup, scrolling screenshots, Google Lens, and direct sharing.',
                        ),
                        const Divider(height: 24),
                        _FeatureRow(
                          icon: Symbols.lock_outline_rounded,
                          title: '100% Private & Zero Permissions',
                          desc: 'Switchly does not read window content or user keystrokes. The service only triggers the Android take-screenshot global action.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.title, required this.desc});

  final String step;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: colors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
