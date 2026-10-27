import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/tiles/tile_catalog.dart';

/// Lists the available tiles. Per-tile status and settings come with the config UI.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Switchly')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          for (final tile in tileCatalog)
            Card(
              child: ListTile(
                leading: Icon(tile.icon),
                title: Text(tile.name),
                subtitle: Text(tile.description),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.addTiles),
        icon: const Icon(Icons.add),
        label: const Text('Add tiles'),
      ),
    );
  }
}
