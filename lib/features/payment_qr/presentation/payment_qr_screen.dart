import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_chip.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/payment_qr_bloc.dart';
import '../data/payment_qr.dart';

/// Add, rename, reorder and delete the QR codes the Payment QR tile shows.
class PaymentQrScreen extends StatelessWidget {
  const PaymentQrScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<PaymentQrBloc>();
    // Uses Android's photo picker: no storage permission needed.
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !context.mounted) return;
    final name = await _askName(context, title: 'Name this QR');
    if (name != null) bloc.add(PaymentQrAdded(image.path, name));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentQrBloc>().state;
    final qrs = state.qrs;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Symbols.add_photo_alternate_rounded),
        label: const Text('Add QR'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Payment QR')),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _IntroCard()),
          ),
          if (state.loaded && qrs.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
          else ...[
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SectionHeader('Saved', subtitle: 'Tap to preview. The first one opens by default.'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverReorderableList(
                itemCount: qrs.length,
                onReorderItem: (from, to) {
                  HapticFeedback.mediumImpact();
                  context.read<PaymentQrBloc>().add(PaymentQrsReordered(from, to));
                },
                proxyDecorator: (child, _, animation) => AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) => Transform.scale(
                    scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
                    child: Material(type: MaterialType.transparency, child: child),
                  ),
                  child: child,
                ),
                itemBuilder: (context, i) => _QrCard(key: ValueKey(qrs[i].id), qr: qrs[i], index: i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Name sheet with quick picks for common Nepali wallets.
Future<String?> _askName(BuildContext context, {required String title, String? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _NameSheet(title: title, initial: initial),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  static const _presets = ['eSewa', 'Khalti', 'Fonepay', 'IME Pay', 'Bank'];
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  SelectChip(label: p, selected: name == p, onTap: () => _controller.text = p),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. eSewa, Nabil Bank'),
              onSubmitted: (_) => name.isEmpty ? null : Navigator.of(context).pop(name),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: name.isEmpty ? null : () => Navigator.of(context).pop(name),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
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
                const TileIcon(Symbols.qr_code_2_rounded, active: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Show your QR at a shop without opening any app. It opens at full brightness, '
                    'even on the lock screen.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (canRequestAddTile(context)) ...[
              const SizedBox(height: 16),
              const AddTileButton(paymentQrTile),
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
          const TileIcon(Symbols.qr_code_2_rounded, size: 72),
          const SizedBox(height: 20),
          Text('No QR codes yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Open eSewa, Khalti or your bank app, take a screenshot of your "receive money" QR, '
            'then add it here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({super.key, required this.qr, required this.index});

  final PaymentQr qr;
  final int index;

  void _preview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: Image.file(File(qr.path), fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                Text(
                  qr.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final bloc = context.read<PaymentQrBloc>();
    final name = await _askName(context, title: 'Rename', initial: qr.name);
    if (name != null) bloc.add(PaymentQrRenamed(qr.id, name));
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<PaymentQrBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${qr.name}”?'),
        content: const Text('The saved copy of the image is removed. Your gallery is not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) bloc.add(PaymentQrDeleted(qr.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () => _preview(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Symbols.drag_indicator_rounded, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Image.file(File(qr.path), fit: BoxFit.contain, cacheWidth: 192),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(qr.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Symbols.more_vert_rounded),
                  onSelected: (action) => action == 'rename' ? _rename(context) : _delete(context),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: ListTile(leading: Icon(Symbols.edit_rounded), title: Text('Rename')),
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
