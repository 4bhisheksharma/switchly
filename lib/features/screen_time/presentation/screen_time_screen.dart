import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/widgets/section_header.dart';
import '../bloc/screen_time_bloc.dart';

class AppScreenTimeScreen extends StatefulWidget {
  const AppScreenTimeScreen({super.key});

  @override
  State<AppScreenTimeScreen> createState() => _AppScreenTimeScreenState();
}

class _AppScreenTimeScreenState extends State<AppScreenTimeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

    return Scaffold(
      appBar: AppBar(
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Quick Settings Tile Live Preview Card
          _TilePreviewCard(state: state),
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

          // Preferences & Tile Behavior
          if (state.config != null) ...[
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: Icon(Symbols.launch_rounded, color: scheme.primary),
                title: Text(
                  'Launch app on tile tap',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Tapping the Quick Settings tile will directly open ${state.config!.appName}.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                value: state.config!.openAppOnTap,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  context.read<ScreenTimeBloc>().add(ScreenTimeOpenOnTapToggled(val));
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // App Selection Section Header
          SectionHeader(
            'Select App to Track',
            trailing: Text(
              '${filteredApps.length} apps',
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),

          // Search Filter Input
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search installed apps...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                prefixIcon: Icon(Symbols.search_rounded, size: 20, color: scheme.onSurfaceVariant),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // App List Container
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredApps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  _query.isEmpty ? 'No launchable apps found' : 'No apps match "$_query"',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredApps.length,
                separatorBuilder: (context, i) => Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  final isSelected = state.config?.packageName == app.package;

                  return InkWell(
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(20) : Radius.zero,
                      bottom: index == filteredApps.length - 1
                          ? const Radius.circular(20)
                          : Radius.zero,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<ScreenTimeBloc>().add(ScreenTimeAppSelected(app));
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
                                color: scheme.surfaceContainerHighest,
                                child: const Icon(Symbols.apps_rounded, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? scheme.primary : scheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                color: isSelected
                                    ? scheme.primary.withValues(alpha: 0.15)
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                app.formattedUsage,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected
                                ? Symbols.radio_button_checked_rounded
                                : Symbols.radio_button_unchecked_rounded,
                            size: 22,
                            color: isSelected ? scheme.primary : scheme.outlineVariant,
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
    );
  }
}

class _TilePreviewCard extends StatelessWidget {
  const _TilePreviewCard({required this.state});

  final ScreenTimeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasApp = state.config != null;
    final active = hasApp && state.currentAppMillis > 0;

    final String label = hasApp
        ? '${state.config!.appName}: ${state.currentAppFormatted}'
        : 'Screen time';
    final String subtitle = hasApp
        ? '${state.currentAppFormatted} today'
        : (state.hasPermission ? 'Select an app below' : 'Permission required');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'QUICK SETTINGS TILE PREVIEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primary.withValues(alpha: 0.15)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  active ? 'Active' : (hasApp ? 'Configured' : 'Inactive'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Simulating the actual Quick Settings Tile Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.timer_rounded,
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active ? scheme.onPrimary : scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: active
                              ? scheme.onPrimary.withValues(alpha: 0.8)
                              : scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
            'Android requires Usage Access permission to allow Switchly to calculate app screen times locally on your device.',
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
