import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/quick_texts_bloc.dart';
import '../data/quick_text.dart';
import 'quick_text_editor_sheet.dart';

/// Manage the snippets the Quick texts tile offers.
class QuickTextsScreen extends StatelessWidget {
  const QuickTextsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuickTextsBloc>().state;
    final texts = state.texts;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Symbols.add_rounded),
        label: const Text('New text'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Quick texts')),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _IntroCard()),
          ),
          if (state.loaded && texts.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
          else ...[
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SectionHeader('Saved', subtitle: 'Tap to copy. Drag to change the order in the tile.'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverReorderableList(
                itemCount: texts.length,
                onReorderItem: (from, to) {
                  HapticFeedback.mediumImpact();
                  context.read<QuickTextsBloc>().add(QuickTextsReordered(from, to));
                },
                proxyDecorator: (child, _, animation) => AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) => Transform.scale(
                    scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
                    child: Material(type: MaterialType.transparency, child: child),
                  ),
                  child: child,
                ),
                itemBuilder: (context, i) =>
                    _QuickTextCard(key: ValueKey(texts[i].id), text: texts[i], index: i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<QuickTextsBloc>();
    final text = await showQuickTextEditor(context);
    if (text != null) bloc.add(QuickTextSaved(text));
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const TileIcon(Symbols.content_paste_rounded, active: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Pull down Quick Settings, tap Quick texts, pick one. It is copied and you are '
                    'back in your app, ready to paste.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (canRequestAddTile(context)) ...[
              const SizedBox(height: 16),
              const AddTileButton(quickTextsTile),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TileIcon(Symbols.notes_rounded, size: 72),
          const SizedBox(height: 20),
          Text('No quick texts yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Save things you type again and again: your address, a bank account number, '
            'an email signature or a standard reply.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _QuickTextCard extends StatelessWidget {
  const _QuickTextCard({super.key, required this.text, required this.index});

  final QuickText text;
  final int index;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text.text));
    HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Copied “${text.displayTitle}”')));
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<QuickTextsBloc>();
    final updated = await showQuickTextEditor(context, editing: text);
    if (updated != null) bloc.add(QuickTextSaved(updated));
  }

  void _delete(BuildContext context) {
    final bloc = context.read<QuickTextsBloc>()..add(QuickTextDeleted(text.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted “${text.displayTitle}”'),
          action: SnackBarAction(label: 'Undo', onPressed: () => bloc.add(QuickTextRestored(text, index))),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () => _copy(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Icon(Symbols.drag_indicator_rounded, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.displayTitle, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        text.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Symbols.more_vert_rounded),
                  onSelected: (action) => action == 'edit' ? _edit(context) : _delete(context),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(leading: Icon(Symbols.edit_rounded), title: Text('Edit')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(leading: Icon(Symbols.delete_rounded), title: Text('Delete')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
