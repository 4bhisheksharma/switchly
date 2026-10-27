import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';
import '../bloc/dns_bloc.dart';
import '../data/dns_models.dart';
import 'provider_editor_sheet.dart';

/// Live status, a quick switcher and the tile-cycle editor for Private DNS.
/// Changes save immediately; there's no "Apply" step.
class DnsScreen extends StatelessWidget {
  const DnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DnsBloc>().state;
    final providers = state.config.providers;

    return BlocListener<DnsBloc, DnsState>(
      listenWhen: (prev, next) => next.applyFailures > prev.applyFailures,
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't change Private DNS."),
          action: SnackBarAction(label: 'Set up', onPressed: () => showPermissionSheet(context)),
        ),
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Private DNS')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.list(
                children: [
                  const _LiveCard(),
                  const SectionHeader('Switch now'),
                  const _QuickSwitcher(),
                  const SectionHeader(
                    'Tile cycle',
                    subtitle: 'Each tap on the tile moves to the next enabled state, top to bottom.',
                  ),
                  Card(
                    child: Column(
                      children: [
                        _FixedStateRow(
                          mode: PrivateDnsMode.off,
                          icon: Symbols.cloud_off_rounded,
                          title: 'Off',
                          subtitle: "Use your network's regular DNS",
                          included: state.config.includeOff,
                        ),
                        const Divider(height: 1, indent: 76),
                        _FixedStateRow(
                          mode: PrivateDnsMode.automatic,
                          icon: Symbols.auto_mode_rounded,
                          title: 'Automatic',
                          subtitle: 'Encrypt when the network supports it',
                          included: state.config.includeAutomatic,
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(
                    'Providers',
                    trailing: Text(
                      'Drag to reorder',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverReorderableList(
                itemCount: providers.length,
                onReorderItem: (from, to) {
                  HapticFeedback.mediumImpact();
                  context.read<DnsBloc>().add(DnsProvidersReordered(from, to));
                },
                proxyDecorator: (child, _, animation) => AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) => Transform.scale(
                    scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
                    child: Material(type: MaterialType.transparency, child: child),
                  ),
                  child: child,
                ),
                itemBuilder: (context, index) => _ProviderCard(
                  key: ValueKey(providers[index].id),
                  provider: providers[index],
                  index: index,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  onPressed: () => _addProvider(context),
                  icon: const Icon(Symbols.add_rounded),
                  label: const Text('Add custom provider'),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 48),
              sliver: SliverToBoxAdapter(child: _InfoNote()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProvider(BuildContext context) async {
    final bloc = context.read<DnsBloc>();
    final provider = await showProviderEditor(context, existing: bloc.state.config.providers);
    if (provider != null) bloc.add(DnsProviderSaved(provider));
  }
}

/// Shows "Keep at least two states" when the user tries to empty the cycle.
bool _guardCycle(BuildContext context, {required bool removing}) {
  if (!removing || context.read<DnsBloc>().state.config.canRemoveFromCycle) return true;
  HapticFeedback.heavyImpact();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('The tile needs at least two states to switch between.')));
  return false;
}

class _LiveCard extends StatelessWidget {
  const _LiveCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<DnsBloc>().state;
    final active = state.live?.isEncrypted ?? false;
    final onCard = active ? Colors.white : colors.onSurface;
    final onCardMuted = active ? Colors.white.withValues(alpha: 0.8) : colors.onSurfaceVariant;

    final detail = switch (state.live?.mode) {
      PrivateDnsMode.hostname => state.live!.host ?? '',
      PrivateDnsMode.off => 'DNS queries are not encrypted',
      PrivateDnsMode.automatic => 'Encrypted only when the network supports it',
      null => '',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: active ? null : colors.surfaceContainerLow,
        border: active ? null : Border.all(color: colors.outlineVariant),
        gradient: active ? AppTheme.brandGradient : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.18) : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  active ? Symbols.encrypted_rounded : Symbols.dns_rounded,
                  fill: active ? 1 : 0,
                  color: active ? Colors.white : colors.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const Spacer(),
              if (state.applying)
                SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: onCard)),
            ],
          ),
          const SizedBox(height: 20),
          Text('CURRENTLY USING', style: theme.textTheme.labelSmall?.copyWith(color: onCardMuted, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              state.liveLabel,
              key: ValueKey(state.liveLabel),
              style: theme.textTheme.headlineMedium?.copyWith(color: onCard),
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: theme.textTheme.bodyMedium?.copyWith(color: onCardMuted)),
          if (canRequestAddTile(context)) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              style: active
                  ? FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5))
                  : null,
              onPressed: () => requestAddTile(context, privateDnsTile),
              icon: const Icon(Symbols.add_to_home_screen_rounded, size: 20),
              label: const Text('Add to Quick Settings'),
            ),
          ],
        ],
      ),
    );
  }
}

/// One chip per state, including providers not in the cycle. Tapping applies immediately.
class _QuickSwitcher extends StatelessWidget {
  const _QuickSwitcher();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DnsBloc>().state;
    final hasPermission = context.select((SetupBloc bloc) => bloc.state.hasPermission);
    final live = state.live;

    void apply(PrivateDnsState target) {
      if (!hasPermission) {
        showPermissionSheet(context);
        return;
      }
      HapticFeedback.selectionClick();
      context.read<DnsBloc>().add(DnsApplyRequested(target));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StateChip(
          label: 'Off',
          selected: live?.mode == PrivateDnsMode.off,
          onTap: () => apply(const PrivateDnsState(PrivateDnsMode.off)),
        ),
        _StateChip(
          label: 'Automatic',
          selected: live?.mode == PrivateDnsMode.automatic,
          onTap: () => apply(const PrivateDnsState(PrivateDnsMode.automatic)),
        ),
        for (final p in state.config.providers)
          _StateChip(
            label: p.name,
            selected: live?.isProvider(p) ?? false,
            onTap: () => apply(PrivateDnsState(PrivateDnsMode.hostname, p.host)),
          ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? colors.primary : colors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Symbols.check_rounded, size: 16, color: colors.onPrimary, weight: 600),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: selected ? colors.onPrimary : colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixedStateRow extends StatelessWidget {
  const _FixedStateRow({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.included,
  });

  final PrivateDnsMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool included;

  @override
  Widget build(BuildContext context) {
    final isLive = context.select((DnsBloc bloc) => bloc.state.live?.mode == mode);

    void toggle() {
      if (!_guardCycle(context, removing: included)) return;
      HapticFeedback.selectionClick();
      context.read<DnsBloc>().add(DnsFixedStateToggled(mode));
    }

    return ListTile(
      onTap: toggle,
      leading: TileIcon(icon, size: 40),
      title: Row(
        children: [
          Flexible(child: Text(title)),
          if (isLive) ...[const SizedBox(width: 8), const StatusPill('Active', highlighted: true)],
        ],
      ),
      subtitle: Text(subtitle),
      trailing: Switch(value: included, onChanged: (_) => toggle()),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({super.key, required this.provider, required this.index});

  final DnsProvider provider;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLive = context.select((DnsBloc bloc) => bloc.state.live?.isProvider(provider) ?? false);

    void toggle() {
      if (!_guardCycle(context, removing: provider.enabled)) return;
      HapticFeedback.selectionClick();
      context.read<DnsBloc>().add(DnsProviderToggled(provider.id));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 12, 14),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Symbols.drag_indicator_rounded, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: provider.enabled ? 1 : 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(provider.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                            ),
                            if (isLive) ...[const SizedBox(width: 8), const StatusPill('Active', highlighted: true)],
                            if (provider.isCustom && !isLive) ...[const SizedBox(width: 8), const StatusPill('Custom')],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.host,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 0.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (provider.tagline != null) ...[
                          const SizedBox(height: 6),
                          Text(provider.tagline!, style: theme.textTheme.labelMedium?.copyWith(color: colors.primary)),
                        ],
                      ],
                    ),
                  ),
                ),
                _ProviderMenu(provider: provider, index: index),
                Switch(value: provider.enabled, onChanged: (_) => toggle()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ProviderAction { copy, edit, delete }

class _ProviderMenu extends StatelessWidget {
  const _ProviderMenu({required this.provider, required this.index});

  final DnsProvider provider;
  final int index;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProviderAction>(
      tooltip: 'More',
      icon: const Icon(Symbols.more_vert_rounded),
      onSelected: (action) => _handle(context, action),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _ProviderAction.copy,
          child: ListTile(leading: Icon(Symbols.content_copy_rounded), title: Text('Copy hostname')),
        ),
        if (provider.isCustom) ...[
          const PopupMenuItem(
            value: _ProviderAction.edit,
            child: ListTile(leading: Icon(Symbols.edit_rounded), title: Text('Edit')),
          ),
          const PopupMenuItem(
            value: _ProviderAction.delete,
            child: ListTile(leading: Icon(Symbols.delete_rounded), title: Text('Delete')),
          ),
        ],
      ],
    );
  }

  Future<void> _handle(BuildContext context, _ProviderAction action) async {
    final bloc = context.read<DnsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _ProviderAction.copy:
        await Clipboard.setData(ClipboardData(text: provider.host));
        messenger.showSnackBar(const SnackBar(content: Text('Hostname copied')));
      case _ProviderAction.edit:
        final updated = await showProviderEditor(context, existing: bloc.state.config.providers, editing: provider);
        if (updated != null) bloc.add(DnsProviderSaved(updated));
      case _ProviderAction.delete:
        if (!_guardCycle(context, removing: provider.enabled)) return;
        bloc.add(DnsProviderDeleted(provider.id));
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Removed ${provider.name}'),
              action: SnackBarAction(label: 'Undo', onPressed: () => bloc.add(DnsProviderRestored(provider, index))),
            ),
          );
    }
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Symbols.info_rounded, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Private DNS uses DNS-over-TLS on port 853. Some Wi-Fi networks block it. If pages '
            'stop loading, switch to Off or Automatic.',
            style: theme.textTheme.bodySmall?.copyWith(color: color, height: 1.5),
          ),
        ),
      ],
    );
  }
}
