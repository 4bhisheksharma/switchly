import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../bloc/setup_bloc.dart';
import '../data/setup_repository.dart';

/// Whether the system "Add tile" prompt is available (Android 13+).
bool canRequestAddTile(BuildContext context) =>
    context.select((SetupBloc bloc) => bloc.state.device?.supportsAddTileRequest ?? false);

/// Shows the system prompt to add [tile], then reports the outcome in a snackbar.
Future<void> requestAddTile(BuildContext context, TileDefinition tile) async {
  final result = await context.read<SetupRepository>().requestAddTile(tile.id);
  if (!context.mounted) return;
  final message = switch (result) {
    AddTileResult.added => '${tile.name} added to Quick Settings',
    AddTileResult.alreadyAdded => '${tile.name} is already in Quick Settings',
    AddTileResult.notAdded => '${tile.name} was not added',
    AddTileResult.unsupported || AddTileResult.error => "Couldn't add it automatically. Add it from the Quick Settings editor.",
  };
  final failed = result == AddTileResult.unsupported || result == AddTileResult.error;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: failed ? SnackBarAction(label: 'How', onPressed: () => showAddTilesHelp(context)) : null,
    ),
  );
}

/// "Add to Quick Settings" for a tile screen's hero card. Only show it when
/// [canRequestAddTile] is true.
class AddTileButton extends StatelessWidget {
  const AddTileButton(this.tile, {super.key, this.onGradient = false});

  final TileDefinition tile;

  /// White button for use on the brand gradient.
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: onGradient
          ? FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5))
          : null,
      onPressed: () => requestAddTile(context, tile),
      icon: const Icon(Symbols.add_to_home_screen_rounded, size: 20),
      label: const Text('Add to Quick Settings'),
    );
  }
}

/// Manual steps for adding tiles; works on every Android version and OEM.
Future<void> showAddTilesHelp(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add tiles to Quick Settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            const _HelpStep(icon: Symbols.swipe_down_rounded, text: 'Swipe down twice from the top of the screen.'),
            const _HelpStep(icon: Symbols.edit_rounded, text: 'Tap the edit (pencil) button.'),
            const _HelpStep(icon: Symbols.drag_indicator_rounded, text: 'Drag Switchly tiles into your active tiles.'),
            const _HelpStep(
              icon: Symbols.info_rounded,
              text: 'Long-press any Switchly tile later to jump straight to its settings.',
            ),
          ],
        ),
      );
    },
  );
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
