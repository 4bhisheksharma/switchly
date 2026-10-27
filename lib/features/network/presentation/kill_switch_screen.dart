import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/network_bloc.dart';
import 'app_picker_sheet.dart';

/// Turn the kill switch on/off and choose the apps that stay online.
class KillSwitchScreen extends StatefulWidget {
  const KillSwitchScreen({super.key});

  @override
  State<KillSwitchScreen> createState() => _KillSwitchScreenState();
}

class _KillSwitchScreenState extends State<KillSwitchScreen> {
  @override
  void initState() {
    super.initState();
    // Icons for the exception list.
    context.read<NetworkBloc>().add(const InstalledAppsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<NetworkBloc>().state;
    final on = state.killSwitchOn;
    final allowed = state.allowedApps;

    return BlocListener<NetworkBloc, NetworkState>(
      listenWhen: (prev, next) => next.failures > prev.failures,
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The kill switch didn't start. Allow the VPN request to use it.")),
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Kill switch')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList.list(
                children: [
                  HeroStatusCard(
                    icon: on ? Symbols.public_off_rounded : Symbols.public_rounded,
                    label: 'Internet',
                    value: on ? 'Blocked' : 'Online',
                    detail: on
                        ? (allowed.isEmpty
                            ? 'Every app is offline'
                            : 'Every app is offline except ${allowed.length} you chose')
                        : 'Cut off every app instantly, for focus, privacy or saving data',
                    active: on,
                    busy: state.killSwitchBusy,
                    action: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          style: on
                              ? FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF4F46E5),
                                )
                              : null,
                          onPressed: state.killSwitchBusy
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  context.read<NetworkBloc>().add(KillSwitchSet(!on));
                                },
                          icon: Icon(on ? Symbols.public_rounded : Symbols.block_rounded, size: 20),
                          label: Text(on ? 'Restore internet' : 'Block internet'),
                        ),
                        if (canRequestAddTile(context) && !on) const AddTileButton(killSwitchTile),
                      ],
                    ),
                  ),
                  SectionHeader(
                    'Stays online',
                    subtitle: 'These apps keep their connection while everything else is blocked.',
                    trailing: TextButton.icon(
                      onPressed: () => showAppPicker(context),
                      icon: const Icon(Symbols.add_rounded, size: 18),
                      label: const Text('Choose'),
                    ),
                  ),
                  if (allowed.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Symbols.apps_rounded, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'No exceptions. Add a messenger or music app to keep it working.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final (i, package) in allowed.indexed) ...[
                            if (i > 0) const Divider(height: 1, indent: 72),
                            _AllowedAppRow(package: package),
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
}

class _AllowedAppRow extends StatelessWidget {
  const _AllowedAppRow({required this.package});

  final String package;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NetworkBloc>().state;
    final app = state.appFor(package);
    return ListTile(
      leading: app != null
          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(app.icon, width: 40, height: 40))
          : const SizedBox.square(dimension: 40, child: Icon(Symbols.android_rounded)),
      title: Text(app?.label ?? package),
      subtitle: app != null ? null : const Text('Not installed'),
      trailing: IconButton(
        tooltip: 'Remove',
        icon: const Icon(Symbols.close_rounded),
        onPressed: () => context.read<NetworkBloc>().add(
              AllowedAppsChanged([...state.allowedApps]..remove(package)),
            ),
      ),
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
              "Works through Android's VPN feature, entirely on your phone: traffic is dropped, never "
              'sent anywhere or inspected. Android allows one VPN at a time, so this replaces any other '
              'VPN while it is on.',
              style: theme.textTheme.bodySmall?.copyWith(color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
