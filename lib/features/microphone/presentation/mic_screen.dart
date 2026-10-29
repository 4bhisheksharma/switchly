import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/mic_bloc.dart';
import '../data/mic_models.dart';

/// Manage microphone routing and test input levels.
class MicScreen extends StatelessWidget {
  const MicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<MicBloc>().state;
    final bloc = context.read<MicBloc>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Microphone')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList.list(
              children: [
                HeroStatusCard(
                  icon: Symbols.mic_rounded,
                  label: 'Current Routing',
                  value: state.currentModeTitle,
                  detail: state.currentModeSubtitle,
                  active: state.isManualOverride,
                  busy: state.isLoading,
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (state.isManualOverride)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4F46E5),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            bloc.add(const MicModeSelected('auto'));
                          },
                          icon: const Icon(Symbols.auto_mode_rounded, size: 20),
                          label: const Text('Reset to Auto'),
                        ),
                      if (canRequestAddTile(context))
                        AddTileButton(micSwitcherTile, onGradient: state.isManualOverride),
                    ],
                  ),
                ),
                const SectionHeader(
                  'Connected Microphones',
                  subtitle: 'Tap any connected microphone to force route calls and voice audio to it.',
                ),
                Card(
                  child: Column(
                    children: [
                      _DeviceRow(
                        title: 'Auto (System Default)',
                        subtitle: 'Automatically follow Android default audio policy',
                        icon: Symbols.auto_mode_rounded,
                        isSelected: state.isAutoSelected,
                        isConnected: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          bloc.add(const MicModeSelected('auto'));
                        },
                      ),
                      const Divider(height: 1, indent: 76),
                      _DeviceRow(
                        title: 'Phone Microphone',
                        subtitle: 'Built-in device mic with hardware noise reduction',
                        icon: Symbols.phone_android_rounded,
                        isSelected: state.isPhoneSelected,
                        isConnected: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          bloc.add(const MicModeSelected('phone'));
                        },
                      ),
                      const Divider(height: 1, indent: 76),
                      _DeviceRow(
                        title: _deviceTitle(state.devices, 'earbuds', 'Bluetooth Earbuds'),
                        subtitle: _deviceSubtitle(state.devices, 'earbuds', 'Bluetooth wireless audio input'),
                        icon: Symbols.headphones_rounded,
                        isSelected: state.isEarbudsSelected,
                        isConnected: state.availableModes.contains('earbuds'),
                        onTap: state.availableModes.contains('earbuds')
                            ? () {
                                HapticFeedback.selectionClick();
                                bloc.add(const MicModeSelected('earbuds'));
                              }
                            : null,
                      ),
                      const Divider(height: 1, indent: 76),
                      _DeviceRow(
                        title: _deviceTitle(state.devices, 'earphones', 'Wired Earphones'),
                        subtitle: _deviceSubtitle(state.devices, 'earphones', '3.5mm jack or USB-C headset'),
                        icon: Symbols.headset_mic_rounded,
                        isSelected: state.isEarphonesSelected,
                        isConnected: state.availableModes.contains('earphones'),
                        onTap: state.availableModes.contains('earphones')
                            ? () {
                                HapticFeedback.selectionClick();
                                bloc.add(const MicModeSelected('earphones'));
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SectionHeader(
                  'Microphone Input Test',
                  subtitle: 'Speak aloud to verify audio input is actively captured by your selected mic.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TileIcon(
                              state.isTesting ? Symbols.graphic_eq_rounded : Symbols.mic_rounded,
                              size: 44,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.isTesting ? 'Testing active...' : 'Live Input Level',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.isTesting
                                        ? 'Recording short samples in communication mode'
                                        : 'Tap test to see live volume meter',
                                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                bloc.add(const MicTestToggled());
                              },
                              icon: Icon(
                                state.isTesting ? Symbols.stop_rounded : Symbols.play_arrow_rounded,
                                size: 20,
                              ),
                              label: Text(state.isTesting ? 'Stop' : 'Test'),
                            ),
                          ],
                        ),
                        if (state.isTesting) ...[
                          const SizedBox(height: 20),
                          _MicLevelBar(level: state.testLevel),
                        ],
                      ],
                    ),
                  ),
                ),
                const SectionHeader(
                  'About Audio Routing',
                  subtitle: 'How Quick Settings mic switching works on Android.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoBullet(
                          icon: Symbols.call_rounded,
                          title: 'Calls & VoIP Apps',
                          body:
                              'Phone calls, WhatsApp, Google Meet, Zoom, Telegram, and Discord route their voice capture through your selected mic.',
                        ),
                        const SizedBox(height: 14),
                        _InfoBullet(
                          icon: Symbols.tune_rounded,
                          title: 'Quick Settings Cycling',
                          body:
                              'Each tap on the Quick Settings tile cycles to the next connected mic (Phone → Earbuds → Earphones → Auto). Disconnected devices are skipped automatically.',
                        ),
                        const SizedBox(height: 14),
                        _InfoBullet(
                          icon: Symbols.bolt_rounded,
                          title: 'No Root or ADB Required',
                          body:
                              'Uses standard Android audio communication routing APIs. Works immediately without special system permissions.',
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

  static String _deviceTitle(List<MicDeviceItem> devices, String mode, String fallback) {
    final dev = devices.firstOrNullWhere((d) => d.mode == mode && d.isConnected);
    return dev?.name ?? fallback;
  }

  static String _deviceSubtitle(List<MicDeviceItem> devices, String mode, String fallback) {
    final dev = devices.firstOrNullWhere((d) => d.mode == mode && d.isConnected);
    if (dev != null) {
      return 'Connected (${dev.type})';
    }
    return 'Not connected';
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isConnected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isConnected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: isConnected,
      onTap: onTap,
      leading: TileIcon(icon, size: 44),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isConnected)
            const StatusPill('Disconnected')
          else if (isSelected)
            const StatusPill('Active', highlighted: true)
          else
            const StatusPill('Ready'),
          const SizedBox(width: 8),
          Icon(
            isSelected ? Symbols.check_circle_rounded : Symbols.radio_button_unchecked_rounded,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _MicLevelBar extends StatelessWidget {
  const _MicLevelBar({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = level.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Input Amplitude',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              '${(clamped * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: clamped > 0.05 ? const Color(0xFF10B981) : scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 12,
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 70),
                  widthFactor: clamped.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1),
                          clamped > 0.6 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(body, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? firstOrNullWhere(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
