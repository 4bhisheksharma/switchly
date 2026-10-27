import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../dns/bloc/dns_bloc.dart';
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';
import '../bloc/profiles_bloc.dart';
import '../data/profile_models.dart';

/// List, apply and restore profiles.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfilesBloc>().state;
    final dnsConfig = context.select((DnsBloc bloc) => bloc.state.config);
    final active = state.active;

    return BlocListener<ProfilesBloc, ProfilesState>(
      listenWhen: (prev, next) => next.failures > prev.failures,
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Some settings couldn't be changed. Finish setup, or turn on the kill switch once to allow it."),
        ),
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).pushNamed(AppRouter.profileEditor),
          icon: const Icon(Symbols.add_rounded),
          label: const Text('New profile'),
        ),
        body: CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Profiles')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList.list(
                children: [
                  if (active != null)
                    HeroStatusCard(
                      icon: active.iconData,
                      label: 'Active profile',
                      value: active.name,
                      detail: active.summary(dnsConfig).join(' · '),
                      active: true,
                      busy: state.busy,
                      action: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                        onPressed: state.busy
                            ? null
                            : () => context.read<ProfilesBloc>().add(const ProfileRestoreRequested()),
                        icon: const Icon(Symbols.restart_alt_rounded, size: 20),
                        label: const Text('Restore previous settings'),
                      ),
                    )
                  else
                    HeroStatusCard(
                      icon: Symbols.tune_rounded,
                      label: 'Active profile',
                      value: 'None',
                      detail: 'Apply a profile to change several settings at once. Restore puts everything back.',
                      busy: state.busy,
                      action: canRequestAddTile(context) ? const AddTileButton(profilesTile) : null,
                    ),
                  if (state.loaded && state.profiles.isEmpty) ...[
                    const SectionHeader('Start from a template', subtitle: 'You can change everything afterwards.'),
                    for (final template in profileTemplates())
                      _ProfileCard(profile: template, isTemplate: true),
                  ] else ...[
                    const SectionHeader('Your profiles'),
                    for (final profile in state.profiles) _ProfileCard(profile: profile),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, this.isTemplate = false});

  final Profile profile;

  /// Templates show "Add" instead of "Apply" and aren't saved until added.
  final bool isTemplate;

  void _apply(BuildContext context) {
    // Everything except the kill switch needs WRITE_SECURE_SETTINGS.
    final needsPermission = profile.dns != null ||
        profile.grayscale != null ||
        profile.animationSpeed != null ||
        profile.wirelessDebugging != null;
    if (needsPermission && !context.read<SetupBloc>().state.hasPermission) {
      showPermissionSheet(context);
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<ProfilesBloc>().add(ProfileApplied(profile.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ProfilesBloc>().state;
    final dnsConfig = context.select((DnsBloc bloc) => bloc.state.config);
    final isActive = !isTemplate && state.activeId == profile.id;
    final summary = profile.summary(dnsConfig);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: isTemplate ? null : () => Navigator.of(context).pushNamed(AppRouter.profileEditor, arguments: profile),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                TileIcon(profile.iconData, active: isActive, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        summary.isEmpty ? 'Changes nothing yet' : summary.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isTemplate)
                  FilledButton.tonal(
                    onPressed: () => context.read<ProfilesBloc>().add(ProfileSaved(profile)),
                    child: const Text('Add'),
                  )
                else if (isActive)
                  const StatusPill('Active', highlighted: true)
                else
                  FilledButton.tonal(
                    onPressed: state.busy || profile.changesNothing ? null : () => _apply(context),
                    child: const Text('Apply'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
