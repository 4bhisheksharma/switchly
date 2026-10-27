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
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';
import '../bloc/display_bloc.dart';
import '../data/display_models.dart';

/// Live speed, a quick switcher and the tile-cycle editor for animation speed.
class AnimationScreen extends StatelessWidget {
  const AnimationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DisplayBloc>().state;
    final scales = state.scales;
    final speed = state.speed;

    final detail = switch (scales) {
      null => '',
      _ when speed == null =>
        'Window ${speedLabel(scales.window)}, transition ${speedLabel(scales.transition)}, '
            'animator ${speedLabel(scales.animator)}',
      _ => speedDescription(speed),
    };

    return BlocListener<DisplayBloc, DisplayState>(
      listenWhen: (prev, next) => next.applyFailures > prev.applyFailures,
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't change the animation speed."),
          action: SnackBarAction(label: 'Set up', onPressed: () => showPermissionSheet(context)),
        ),
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Animation speed')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList.list(
                children: [
                  HeroStatusCard(
                    icon: Symbols.speed_rounded,
                    label: 'Current speed',
                    value: state.speedText,
                    detail: detail,
                    active: state.animationModified,
                    busy: state.applying,
                    action: canRequestAddTile(context)
                        ? AddTileButton(animationSpeedTile, onGradient: state.animationModified)
                        : null,
                  ),
                  const SectionHeader('Set now'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in animationSpeeds)
                        SelectChip(
                          label: speedLabel(s),
                          selected: speed != null && sameSpeed(speed, s),
                          onTap: () => _apply(context, s),
                        ),
                    ],
                  ),
                  const SectionHeader(
                    'Tile cycle',
                    subtitle: 'Each tap on the tile moves to the next selected speed.',
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final (i, s) in animationSpeeds.indexed) ...[
                          if (i > 0) const Divider(height: 1, indent: 76),
                          _CycleRow(speed: s, isLive: speed != null && sameSpeed(speed, s)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _InfoNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _apply(BuildContext context, double speed) {
    if (!context.read<SetupBloc>().state.hasPermission) {
      showPermissionSheet(context);
      return;
    }
    HapticFeedback.selectionClick();
    context.read<DisplayBloc>().add(AnimationSpeedSet(speed));
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.speed, required this.isLive});

  final double speed;
  final bool isLive;

  static IconData _iconFor(double speed) => switch (speed) {
        _ when sameSpeed(speed, 0) => Symbols.motion_photos_off_rounded,
        _ when speed < 1 => Symbols.fast_forward_rounded,
        _ when sameSpeed(speed, 1) => Symbols.play_arrow_rounded,
        _ => Symbols.slow_motion_video_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final config = context.select((DisplayBloc bloc) => bloc.state.animationConfig);
    final included = config.includes(speed);

    void toggle() {
      if (included && !config.canRemove) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('The tile needs at least two speeds to switch between.')));
        return;
      }
      HapticFeedback.selectionClick();
      context.read<DisplayBloc>().add(AnimationCycleSpeedToggled(speed));
    }

    return ListTile(
      onTap: toggle,
      leading: TileIcon(_iconFor(speed), size: 40),
      title: Row(
        children: [
          Flexible(child: Text(speedLabel(speed))),
          if (isLive) ...[const SizedBox(width: 8), const StatusPill('Active', highlighted: true)],
        ],
      ),
      subtitle: Text(speedDescription(speed)),
      trailing: Switch(value: included, onChanged: (_) => toggle()),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.info_rounded, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sets the window, transition and animator scales from Developer options together. '
              'A few apps only pick up a new speed after they restart.',
              style: theme.textTheme.bodySmall?.copyWith(color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
