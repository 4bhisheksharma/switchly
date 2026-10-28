import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/section_header.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/screen_time_bloc.dart';
import '../data/screen_time_config.dart';

class AppScreenTimeScreen extends StatefulWidget {
  const AppScreenTimeScreen({super.key});

  @override
  State<AppScreenTimeScreen> createState() => _AppScreenTimeScreenState();
}

class _AppScreenTimeScreenState extends State<AppScreenTimeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _selectedSlot = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<ScreenTimeBloc>().state;

    final filteredApps = _query.isEmpty
        ? state.apps
        : state.apps
            .where((a) =>
                a.label.toLowerCase().contains(_query.toLowerCase()) ||
                a.package.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final selectedConfig = state.configForSlot(_selectedSlot);
    final selectedTime = state.timeForSlot(_selectedSlot);
    final canAddTiles = canRequestAddTile(context);

    // Find the icon for the currently selected app (if configured)
    final selectedAppItem = selectedConfig != null
        ? state.apps.where((a) => a.package == selectedConfig.packageName).firstOrNull
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('App Screen Time'),
            actions: [
              IconButton(
                tooltip: 'Refresh screen time',
                icon: const Icon(Symbols.refresh_rounded),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<ScreenTimeBloc>().add(const ScreenTimeRefreshed());
                },
              ),
              IconButton(
                tooltip: 'How Quick Settings tiles work',
                icon: const Icon(Symbols.help_outline_rounded),
                onPressed: () => showAddTilesHelp(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList.list(
              children: [
                // Slot selector tabs (Tile 1, Tile 2, Tile 3, Tile 4)
                _SlotPillBar(
                  selectedSlot: _selectedSlot,
                  state: state,
                  onSlotSelected: (slot) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSlot = slot);
                  },
                ),
                const SizedBox(height: 16),

                // Hero status card for the active slot
                _ActiveSlotHeroCard(
                  slot: _selectedSlot,
                  config: selectedConfig,
                  appItem: selectedAppItem,
                  time: selectedTime,
                  canAddTiles: canAddTiles,
                  onAddTileTap: () =>
                      requestAddTile(context, appScreenTimeTileForSlot(_selectedSlot)),
                  onUnassignTap: selectedConfig != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.read<ScreenTimeBloc>().add(ScreenTimeSlotRemoved(_selectedSlot));
                        }
                      : null,
                ),
                const SizedBox(height: 14),

                // Permission Alert if Usage Access is not granted
                if (!state.hasPermission) ...[
                  _PermissionCard(
                    onGrantTap: () {
                      HapticFeedback.mediumImpact();
                      context.read<QsChannel>().openUsageAccessSettings();
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Slot Behavior Settings
                if (selectedConfig != null) ...[
                  Card(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      secondary: Icon(Symbols.launch_rounded, color: scheme.primary),
                      title: Text(
                        'Launch app on tile tap',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Tapping Tile $_selectedSlot in Quick Settings will directly launch ${selectedConfig.appName}.',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      value: selectedConfig.openAppOnTap,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        context
                            .read<ScreenTimeBloc>()
                            .add(ScreenTimeSlotOpenOnTapToggled(_selectedSlot, val));
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // App Picker Header
                SectionHeader(
                  selectedConfig != null
                      ? 'Change app for Tile $_selectedSlot'
                      : 'Choose app for Tile $_selectedSlot',
                  trailing: Text(
                    '${filteredApps.length} apps',
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),

                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search installed apps...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Symbols.search_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Symbols.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // App List in a unified Card
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredApps.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.search_off_rounded,
                            size: 38,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _query.isEmpty ? 'No launchable apps found' : 'No apps match "$_query"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredApps.length,
                      separatorBuilder: (context, i) => Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 16,
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (context, index) {
                        final app = filteredApps[index];
                        final isAssignedToThisSlot = selectedConfig?.packageName == app.package;
                        final otherSlot = state.slotForPackage(app.package);

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context
                                .read<ScreenTimeBloc>()
                                .add(ScreenTimeSlotAssigned(_selectedSlot, app));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    app.icon,
                                    width: 38,
                                    height: 38,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 38,
                                      height: 38,
                                      color: scheme.surfaceContainerHigh,
                                      child: const Icon(Symbols.apps_rounded, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              app.label,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: isAssignedToThisSlot
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: isAssignedToThisSlot
                                                    ? scheme.primary
                                                    : scheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (otherSlot != null && otherSlot != _selectedSlot) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: scheme.surfaceContainerHigh,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Tile $otherSlot',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        app.package,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (app.usageMillis > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAssignedToThisSlot
                                          ? scheme.primary.withValues(alpha: 0.12)
                                          : scheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      app.formattedUsage,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isAssignedToThisSlot
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Icon(
                                  isAssignedToThisSlot
                                      ? Symbols.check_circle_rounded
                                      : Symbols.radio_button_unchecked_rounded,
                                  size: 22,
                                  color: isAssignedToThisSlot
                                      ? scheme.primary
                                      : scheme.outlineVariant,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A clean, modern segmented selector for the 4 tile slots.
class _SlotPillBar extends StatelessWidget {
  const _SlotPillBar({
    required this.selectedSlot,
    required this.state,
    required this.onSlotSelected,
  });

  final int selectedSlot;
  final ScreenTimeState state;
  final ValueChanged<int> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: List.generate(4, (index) {
        final slot = index + 1;
        final isSelected = slot == selectedSlot;
        final config = state.configForSlot(slot);
        final hasApp = config != null;
        final time = state.timeForSlot(slot);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 3,
              right: index == 3 ? 0 : 3,
            ),
            child: Material(
              color: isSelected ? scheme.primary : scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSlotSelected(slot),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tile $slot',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasApp ? config.appName : 'Empty',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? scheme.onPrimary.withValues(alpha: 0.85)
                              : (hasApp ? scheme.primary : scheme.onSurfaceVariant),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (hasApp && time.millis > 0) ...[
                        const SizedBox(height: 1),
                        Text(
                          time.formatted,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? scheme.onPrimary.withValues(alpha: 0.75)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// A human, cohesive hero card reflecting the active slot's configuration.
class _ActiveSlotHeroCard extends StatelessWidget {
  const _ActiveSlotHeroCard({
    required this.slot,
    required this.config,
    required this.appItem,
    required this.time,
    required this.canAddTiles,
    required this.onAddTileTap,
    this.onUnassignTap,
  });

  final int slot;
  final ScreenTimeConfig? config;
  final dynamic appItem;
  final ({int millis, String formatted}) time;
  final bool canAddTiles;
  final VoidCallback onAddTileTap;
  final VoidCallback? onUnassignTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasApp = config != null;
    final active = hasApp && time.millis > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Real app icon or timer icon plate
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasApp
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: hasApp && appItem != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            appItem.icon,
                            width: 38,
                            height: 38,
                          ),
                        )
                      : Icon(
                          Symbols.timer_rounded,
                          size: 26,
                          color: scheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'QUICK TILE $slot',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: active
                                ? scheme.primary.withValues(alpha: 0.12)
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            active ? 'Active' : (hasApp ? 'Configured' : 'Unassigned'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: active ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasApp ? config!.appName : 'No app selected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onUnassignTap != null)
                IconButton(
                  tooltip: 'Unassign this tile',
                  icon: const Icon(Symbols.close_rounded, size: 20),
                  onPressed: onUnassignTap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Stats Reading
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hasApp ? time.formatted : '0m',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasApp ? 'screen time today' : 'tap any app below to bind',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Settings Action Bar
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Symbols.add_circle_outline_rounded, size: 18),
                  label: Text(
                    'Add Tile $slot to Quick Settings',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: canAddTiles ? onAddTileTap : () => showAddTilesHelp(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onGrantTap});

  final VoidCallback onGrantTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const amber = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.warning_rounded, color: amber, size: 22),
              const SizedBox(width: 10),
              Text(
                'Usage Access Permission Needed',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Android requires Usage Access permission so Switchly can calculate daily app screen times locally on your device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: amber,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Symbols.settings_rounded, size: 18),
            label: const Text('Grant Usage Access', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: onGrantTap,
          ),
        ],
      ),
    );
  }
}
