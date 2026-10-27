import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../bloc/setup_bloc.dart';
import '../data/setup_repository.dart';

/// Adds tiles to Quick Settings: a system prompt on Android 13+, manual steps below that.
class AddTilesScreen extends StatelessWidget {
  const AddTilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canRequest =
        context.select((SetupBloc bloc) => bloc.state.device?.supportsAddTileRequest ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Add tiles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final tile in tileCatalog)
            Card(
              child: ListTile(
                leading: Icon(tile.icon),
                title: Text(tile.name),
                subtitle: Text(tile.description),
                trailing: canRequest
                    ? FilledButton.tonal(
                        onPressed: () => _requestAdd(context, tile),
                        child: const Text('Add'),
                      )
                    : null,
              ),
            ),
          const SizedBox(height: 16),
          // Shown on every version: some OEM builds reject the add prompt.
          const _ManualInstructions(),
        ],
      ),
    );
  }

  Future<void> _requestAdd(BuildContext context, TileDefinition tile) async {
    final result = await context.read<SetupRepository>().requestAddTile(tile.id);
    if (!context.mounted) return;
    final message = switch (result) {
      AddTileResult.added => '${tile.name} added to Quick Settings',
      AddTileResult.alreadyAdded => '${tile.name} is already in Quick Settings',
      AddTileResult.notAdded => '${tile.name} was not added',
      AddTileResult.unsupported ||
      AddTileResult.error =>
        'Couldn\'t add ${tile.name} automatically. Add it manually below.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ManualInstructions extends StatelessWidget {
  const _ManualInstructions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add manually', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          '1. Swipe down twice to open Quick Settings.\n'
          '2. Tap the edit (pencil) button.\n'
          '3. Find the Switchly tiles and drag them into your active tiles.',
        ),
      ],
    );
  }
}
