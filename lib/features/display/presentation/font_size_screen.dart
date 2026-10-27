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

/// Live font size, a quick switcher and the tile-cycle editor.
class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DisplayBloc>().state;
    final scale = state.fontScale;
    final sdkInt = context.select((SetupBloc bloc) => bloc.state.device?.sdkInt ?? 0);
    final offered = [
      for (final s in fontScales)
        if (s <= maxFontScale(sdkInt)) s,
    ];

    return BlocListener<DisplayBloc, DisplayState>(
      listenWhen: (prev, next) => next.applyFailures > prev.applyFailures,
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't change the font size."),
          action: SnackBarAction(label: 'Set up', onPressed: () => showPermissionSheet(context)),
        ),
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Font size')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList.list(
                children: [
                  HeroStatusCard(
                    icon: Symbols.format_size_rounded,
                    label: 'Current size',
                    value: scale == null ? '—' : fontLabel(scale),
                    detail: scale == null ? '' : fontDescription(scale),
                    active: state.fontModified,
                    action: canRequestAddTile(context)
                        ? AddTileButton(fontSizeTile, onGradient: state.fontModified)
                        : null,
                  ),
                  const SectionHeader('Set now'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in offered)
                        SelectChip(
                          label: fontLabel(s),
                          selected: scale != null && sameSpeed(scale, s),
                          onTap: () => _apply(context, s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _Preview(),
                  const SectionHeader('Tile cycle', subtitle: 'Each tap on the tile moves to the next selected size.'),
                  Card(
                    child: Column(
                      children: [
                        for (final (i, s) in offered.indexed) ...[
                          if (i > 0) const Divider(height: 1, indent: 76),
                          _CycleRow(scale: s, isLive: scale != null && sameSpeed(scale, s)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _apply(BuildContext context, double scale) {
    if (!context.read<SetupBloc>().state.hasPermission) {
      showPermissionSheet(context);
      return;
    }
    HapticFeedback.selectionClick();
    context.read<DisplayBloc>().add(FontScaleSet(scale));
  }
}

/// Sample text. The app follows the system size, so this shows the size actually applied.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Text('Messages, menus and websites will look like this.', style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.scale, required this.isLive});

  final double scale;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final config = context.select((DisplayBloc bloc) => bloc.state.fontConfig);
    final included = config.includes(scale);

    void toggle() {
      if (included && !config.canRemove) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('The tile needs at least two sizes to switch between.')));
        return;
      }
      HapticFeedback.selectionClick();
      context.read<DisplayBloc>().add(FontCycleScaleToggled(scale));
    }

    return ListTile(
      onTap: toggle,
      leading: TileIcon(scale < 1 ? Symbols.text_decrease_rounded : Symbols.text_increase_rounded, size: 40),
      title: Row(
        children: [
          Flexible(child: Text(fontLabel(scale))),
          if (isLive) ...[const SizedBox(width: 8), const StatusPill('Active', highlighted: true)],
        ],
      ),
      subtitle: Text(fontDescription(scale)),
      trailing: Switch(value: included, onChanged: (_) => toggle()),
    );
  }
}
