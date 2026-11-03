import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: const TileIcon(Symbols.brightness_7_rounded, active: true),
                    title: const Text('Full brightness on display'),
                    subtitle: const Text('Maximize display brightness while showing QR for fast scanning.'),
                    value: state.maxBrightness,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      context.read<PaymentQrBloc>().add(PaymentQrMaxBrightnessToggled(val));
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TileIcon(Symbols.widgets_rounded, active: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home screen widget',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Freely resizable · Fast 1-tap shortcut to show your QR',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: GestureDetector(
                            onTap: () => _showPaymentQrPreviewSheet(
                              context,
                              state.qrs.firstOrNull?.name ?? 'Tap to view QR',
                            ),
                            child: _PaymentQrWidgetPreview(
                              qrName: state.qrs.firstOrNull?.name ?? 'Tap to view QR',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showPaymentQrPreviewSheet(
                                context,
                                state.qrs.firstOrNull?.name ?? 'Tap to view QR',
                              ),
                              icon: const Icon(Symbols.preview_rounded, size: 18),
                              label: const Text('Preview'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () async {
                                final channel = context.read<QsChannel>();
                                final success = await channel.requestPinWidget('payment_qr');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Payment QR widget prompt displayed'
                                          : 'To add the widget, touch & hold an empty area on your home screen and choose Switchly.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Symbols.add_to_home_screen_rounded, size: 18),
                              label: const Text('Add Widget'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (canRequestAddTile(context)) const AddTileButton(paymentQrTile),
                OutlinedButton.icon(
                  onPressed: () async {
                    final channel = context.read<QsChannel>();
                    final success = await channel.requestPinWidget('payment_qr');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Payment QR widget prompt displayed'
                              : 'To add the widget, touch & hold your home screen and choose Switchly.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Symbols.widgets_rounded, size: 20),
                  label: const Text('Add Home Widget'),
                ),
              ],
            ),
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

void _showPaymentQrPreviewSheet(BuildContext context, String qrName) {
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
            Text('Payment QR Widget Preview', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'One-tap shortcut directly on your home screen to show your QR instantly.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
                child: _PaymentQrWidgetPreview(qrName: qrName),
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeaturePill(icon: Symbols.aspect_ratio_rounded, label: 'Freely resizable'),
                _FeaturePill(icon: Symbols.bolt_rounded, label: 'Instant 1-tap display'),
                _FeaturePill(icon: Symbols.lock_open_rounded, label: 'Works over lock screen'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final channel = context.read<QsChannel>();
                  final success = await channel.requestPinWidget('payment_qr');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Payment QR widget prompt displayed'
                            : 'To add the widget, touch & hold an empty area on your home screen and choose Switchly.',
                      ),
                    ),
                  );
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

class _PaymentQrWidgetPreview extends StatelessWidget {
  const _PaymentQrWidgetPreview({required this.qrName});

  final String qrName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2C3E)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.qr_code_2_rounded,
            size: 36,
            color: Color(0xFF818CF8),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment QR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            qrName,
            style: const TextStyle(
              color: Color(0xFF8D8B9D),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
