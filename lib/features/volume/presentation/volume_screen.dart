import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/section_header.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/volume_bloc.dart';
import '../data/volume_models.dart';

/// Volume control screen with real-time sliders for Media, Ringtone, Notifications,
/// and Alarm, plus quick presets, ringer modes, and widget previews.
class VolumeScreen extends StatelessWidget {
  const VolumeScreen({super.key});

  Future<void> _requestAddWidget(BuildContext context, String widgetId) async {
    final channel = context.read<QsChannel>();
    final success = await channel.requestPinWidget(widgetId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Widget prompt displayed. Place it on your home screen!'
              : 'To add the widget, touch & hold an empty area on your home screen and choose Switchly.',
        ),
      ),
    );
  }

  void _showWidgetPreview(
    BuildContext context, {
    required String title,
    required String widgetId,
    required Widget previewWidget,
    required String subtitle,
    required List<String> features,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF111827)],
                  ),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: previewWidget,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features
                    .map((f) => _FeaturePill(icon: Symbols.check_circle_rounded, label: f))
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _requestAddWidget(context, widgetId);
                  },
                  icon: const Icon(Symbols.add_to_home_screen_rounded),
                  label: const Text('Add to Home Screen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddTiles = canRequestAddTile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Control'),
        actions: [
          IconButton(
            tooltip: 'System Sound Settings',
            icon: const Icon(Symbols.settings_suggest_rounded),
            onPressed: () => context.read<VolumeBloc>().add(const VolumeSoundSettingsRequested()),
          ),
        ],
      ),
      body: BlocBuilder<VolumeBloc, VolumeState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          final music = snapshot.music;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Master Media Loudness Hero Card
              _buildHeroCard(context, music),
              const SizedBox(height: 16),

              // 2. Ringer Mode Switcher
              _buildRingerModeCard(context, snapshot.ringerMode),
              const SizedBox(height: 20),

              // 3. Quick Settings & Widgets Action Section
              const SectionHeader(
                'Tile & Widgets',
                subtitle: 'Adjust volume sliders directly from notification shade',
              ),
              const SizedBox(height: 8),
              _buildWidgetsAndTilesSection(context, canAddTiles, snapshot),
              const SizedBox(height: 24),

              // 4. Detailed Audio Stream Sliders
              const SectionHeader(
                'Volume Sliders',
                subtitle: 'Fine-tune loudness for every audio stream',
              ),
              const SizedBox(height: 8),
              _StreamSliderTile(
                stream: snapshot.music,
                onChanged: (val) {
                  context.read<VolumeBloc>().add(
                        VolumeLevelChanged(stream: 'music', level: val.round()),
                      );
                },
              ),
              const SizedBox(height: 8),
              _StreamSliderTile(
                stream: snapshot.ring,
                onChanged: (val) {
                  context.read<VolumeBloc>().add(
                        VolumeLevelChanged(stream: 'ring', level: val.round()),
                      );
                },
              ),
              const SizedBox(height: 8),
              _StreamSliderTile(
                stream: snapshot.notification,
                onChanged: (val) {
                  context.read<VolumeBloc>().add(
                        VolumeLevelChanged(stream: 'notification', level: val.round()),
                      );
                },
              ),
              const SizedBox(height: 8),
              _StreamSliderTile(
                stream: snapshot.alarm,
                onChanged: (val) {
                  context.read<VolumeBloc>().add(
                        VolumeLevelChanged(stream: 'alarm', level: val.round()),
                      );
                },
              ),
              const SizedBox(height: 8),
              _StreamSliderTile(
                stream: snapshot.call,
                onChanged: (val) {
                  context.read<VolumeBloc>().add(
                        VolumeLevelChanged(stream: 'call', level: val.round()),
                      );
                },
              ),
              const SizedBox(height: 24),

              // 5. System Flyout Shortcut
              OutlinedButton.icon(
                onPressed: () => context.read<VolumeBloc>().add(const VolumeSystemUiRequested()),
                icon: const Icon(Symbols.open_in_new_rounded, size: 18),
                label: const Text('Show Native Android Volume Panel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, VolumeStreamState music) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  music.isMuted ? Symbols.volume_off_rounded : Symbols.volume_up_rounded,
                  color: scheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media Loudness',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Primary playback volume',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${music.percent}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Master Slider with Step Buttons
          Row(
            children: [
              _buildVolumeStepper(
                context: context,
                icon: Symbols.remove_rounded,
                tooltip: 'Decrease Media Volume',
                size: 36,
                onPressed: music.current > music.min
                    ? () {
                        context.read<VolumeBloc>().add(
                              const VolumeStepAdjusted(stream: 'music', increase: false),
                            );
                      }
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.primary.withValues(alpha: 0.16),
                    thumbColor: scheme.primary,
                    overlayColor: scheme.primary.withValues(alpha: 0.12),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: music.current.toDouble().clamp(music.min.toDouble(), music.max.toDouble()),
                    min: music.min.toDouble(),
                    max: music.max.toDouble(),
                    divisions: (music.max - music.min).clamp(1, 100),
                    onChanged: (val) {
                      context.read<VolumeBloc>().add(
                            VolumeLevelChanged(stream: 'music', level: val.round()),
                          );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildVolumeStepper(
                context: context,
                icon: Symbols.add_rounded,
                tooltip: 'Increase Media Volume',
                size: 36,
                onPressed: music.current < music.max
                    ? () {
                        context.read<VolumeBloc>().add(
                              const VolumeStepAdjusted(stream: 'music', increase: true),
                            );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Preset Chips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0, 25, 50, 75, 100].map((preset) {
              final isCurrent = (music.percent - preset).abs() <= 5;
              final label = preset == 0 ? 'Mute' : (preset == 100 ? 'Max' : '$preset%');
              return Material(
                color: isCurrent ? scheme.primary : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<VolumeBloc>().add(VolumePresetChanged(preset));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? scheme.primary
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isCurrent ? scheme.onPrimary : scheme.onSurface,
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRingerModeCard(BuildContext context, RingerMode currentMode) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.notifications_active_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Ringer Mode',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                currentMode.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<RingerMode>(
            segments: const [
              ButtonSegment(
                value: RingerMode.normal,
                label: Text('Sound'),
                icon: Icon(Symbols.volume_up_rounded, size: 18),
              ),
              ButtonSegment(
                value: RingerMode.vibrate,
                label: Text('Vibrate'),
                icon: Icon(Symbols.vibration_rounded, size: 18),
              ),
              ButtonSegment(
                value: RingerMode.silent,
                label: Text('Silent'),
                icon: Icon(Symbols.volume_off_rounded, size: 18),
              ),
            ],
            selected: {currentMode},
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: scheme.primary.withValues(alpha: 0.16),
              selectedForegroundColor: scheme.primary,
              foregroundColor: scheme.onSurfaceVariant,
              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                context.read<VolumeBloc>().add(VolumeRingerModeChanged(set.first));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetsAndTilesSection(
    BuildContext context,
    bool canAddTiles,
    VolumeSnapshot snapshot,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        // Quick Settings Tile
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Symbols.volume_up_rounded, color: scheme.primary, size: 24),
            ),
            title: const Text('Volume Slider Tile', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Media: ${snapshot.music.percent}% · Tap pops slider dialog'),
            trailing: FilledButton.tonal(
              onPressed: () =>
                  canAddTiles ? requestAddTile(context, volumeTile) : showAddTilesHelp(context),
              child: const Text('Add Tile'),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Widgets Row
        Row(
          children: [
            Expanded(
              child: _WidgetPickerCard(
                title: 'Standard (4x2)',
                subtitle: 'Presets & Loudness Card',
                icon: Symbols.grid_view_rounded,
                onTap: () {
                  _showWidgetPreview(
                    context,
                    title: 'Volume Widget (4x2)',
                    subtitle: 'Displays current loudness with one-tap presets',
                    widgetId: 'volume',
                    features: const [
                      'Freely resizable',
                      'Live loudness readout',
                      'Quick presets: Mute, 30%, 70%, Max',
                    ],
                    previewWidget: _StandardVolumeWidgetPreview(percent: snapshot.music.percent),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WidgetPickerCard(
                title: 'Compact (2x1)',
                subtitle: 'Minimal Volume Badge',
                icon: Symbols.ad_units_rounded,
                onTap: () {
                  _showWidgetPreview(
                    context,
                    title: 'Volume Compact Badge (2x1)',
                    subtitle: 'Clean badge showing current volume percentage',
                    widgetId: 'volume_compact',
                    features: const [
                      'Compact 2x1 / 2x2 badge',
                      'Displays live percentage',
                      'Tap opens Switchly volume controls',
                    ],
                    previewWidget: _CompactVolumeWidgetPreview(percent: snapshot.music.percent),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildVolumeStepper({
  required BuildContext context,
  required IconData icon,
  required String tooltip,
  required VoidCallback? onPressed,
  double size = 34,
}) {
  final scheme = Theme.of(context).colorScheme;
  final enabled = onPressed != null;
  return Tooltip(
    message: tooltip,
    child: Material(
      color: enabled
          ? scheme.primary.withValues(alpha: 0.1)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
    ),
  );
}

class _StreamSliderTile extends StatelessWidget {
  const _StreamSliderTile({
    required this.stream,
    required this.onChanged,
  });

  final VolumeStreamState stream;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stream.icon, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      stream.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stream.percent}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildVolumeStepper(
                context: context,
                icon: Symbols.remove_rounded,
                tooltip: 'Decrease ${stream.label}',
                size: 32,
                onPressed: stream.current > stream.min
                    ? () => onChanged((stream.current - 1)
                        .toDouble()
                        .clamp(stream.min.toDouble(), stream.max.toDouble()))
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.primary.withValues(alpha: 0.16),
                    thumbColor: scheme.primary,
                    overlayColor: scheme.primary.withValues(alpha: 0.12),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: stream.current.toDouble().clamp(stream.min.toDouble(), stream.max.toDouble()),
                    min: stream.min.toDouble(),
                    max: stream.max.toDouble(),
                    divisions: (stream.max - stream.min).clamp(1, 100),
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildVolumeStepper(
                context: context,
                icon: Symbols.add_rounded,
                tooltip: 'Increase ${stream.label}',
                size: 32,
                onPressed: stream.current < stream.max
                    ? () => onChanged((stream.current + 1)
                        .toDouble()
                        .clamp(stream.min.toDouble(), stream.max.toDouble()))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WidgetPickerCard extends StatelessWidget {
  const _WidgetPickerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const Spacer(),
                Icon(Symbols.visibility_rounded, size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Exact simulated in-app preview for the Standard 4x2 Volume Widget.
class _StandardVolumeWidgetPreview extends StatelessWidget {
  const _StandardVolumeWidgetPreview({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33818CF8)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x26818CF8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Symbols.volume_up_rounded,
                  color: Color(0xFF818CF8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Volume Control',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              const Text(
                'Sound On',
                style: TextStyle(
                  color: Color(0xFF8D8B9D),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Percentage readout & Step Controls
          Row(
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Media Loudness',
                style: TextStyle(
                  color: Color(0xFFC4C2D6),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF20212E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '−',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF20212E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Chips Row
          Row(
            children: ['Mute', '30%', '70%', 'Max'].map((preset) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20212E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      preset,
                      style: const TextStyle(color: Color(0xFFC4C2D6), fontSize: 11),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Exact simulated in-app preview for the Compact 2x1 Volume Widget.
class _CompactVolumeWidgetPreview extends StatelessWidget {
  const _CompactVolumeWidgetPreview({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33818CF8)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Symbols.volume_up_rounded, color: Color(0xFF818CF8), size: 16),
              SizedBox(width: 4),
              Text(
                'Volume',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Spacer(),
              Text(
                'Media',
                style: TextStyle(
                  color: Color(0xFF8D8B9D),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF20212E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    '−',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF20212E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Sound On',
            style: TextStyle(
              color: Color(0xFF8D8B9D),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
