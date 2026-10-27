import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_chip.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/power_cubits.dart';
import '../data/power_models.dart';

/// Start/stop Caffeine and edit the tile's duration cycle.
class CaffeineScreen extends StatelessWidget {
  const CaffeineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CaffeineCubit>().state;
    final status = state.status;
    final cubit = context.read<CaffeineCubit>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Caffeine')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList.list(
              children: [
                HeroStatusCard(
                  icon: Symbols.coffee_rounded,
                  label: 'Screen',
                  value: status.on ? 'Staying awake' : 'Normal timeout',
                  detail: caffeineDetail(context, status),
                  active: status.on,
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (status.on)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4F46E5),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            cubit.stop();
                          },
                          icon: const Icon(Symbols.bedtime_rounded, size: 20),
                          label: const Text('Turn off'),
                        ),
                      if (canRequestAddTile(context)) AddTileButton(caffeineTile, onGradient: status.on),
                    ],
                  ),
                ),
                const SectionHeader('Start now'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in caffeineDurations)
                      SelectChip(
                        label: durationLabel(m),
                        selected: status.on && status.minutes == m,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          cubit.start(m);
                        },
                      ),
                  ],
                ),
                const SectionHeader(
                  'Tile cycle',
                  subtitle: 'Each tap on the tile moves to the next duration, then off.',
                ),
                Card(
                  child: Column(
                    children: [
                      for (final (i, m) in caffeineDurations.indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 76),
                        _CycleRow(minutes: m, config: state.config),
                      ],
                    ],
                  ),
                ),
                const SectionHeader('Options'),
                Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    secondary: const TileIcon(Symbols.lock_rounded, size: 40),
                    title: const Text('Turn off when the screen locks'),
                    subtitle: const Text('Pressing the power button ends Caffeine.'),
                    value: state.config.stopOnLock,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      cubit.setStopOnLock(v);
                    },
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

/// "Until 3:45 PM", "Until you turn it off" or a short explanation when off.
String caffeineDetail(BuildContext context, CaffeineStatus status) {
  if (!status.on) return 'The screen turns off as usual';
  final endsAt = status.endsAt;
  if (endsAt == null) return 'Until you turn it off';
  return 'Until ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(endsAt))}';
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.minutes, required this.config});

  final int minutes;
  final CaffeineConfig config;

  @override
  Widget build(BuildContext context) {
    final included = config.includes(minutes);

    void toggle() {
      if (included && !config.canRemove) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('The tile needs at least one duration.')));
        return;
      }
      HapticFeedback.selectionClick();
      context.read<CaffeineCubit>().toggleDuration(minutes);
    }

    final live = context.select((CaffeineCubit c) => c.state.status.on && c.state.status.minutes == minutes);
    return ListTile(
      onTap: toggle,
      leading: TileIcon(minutes == 0 ? Symbols.all_inclusive_rounded : Symbols.timer_rounded, size: 40),
      title: Row(
        children: [
          Flexible(child: Text(durationLabel(minutes))),
          if (live) ...[const SizedBox(width: 8), const StatusPill('Active', highlighted: true)],
        ],
      ),
      trailing: Switch(value: included, onChanged: (_) => toggle()),
    );
  }
}
