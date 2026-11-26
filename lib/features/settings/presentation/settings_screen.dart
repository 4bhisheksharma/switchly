import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/config/app_config.dart';
import '../../../core/platform/qs_channel.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';
import '../../updater/presentation/update_tile.dart';
import '../theme_cubit.dart';
import '../tile_message_cubit.dart';

/// App preferences: appearance, Quick Settings setup, updates, and privacy info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = AppConfig.versionName;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await context.read<QsChannel>().getAppVersion();
      if (mounted && info.versionName.isNotEmpty) {
        setState(() => _version = info.versionName);
      }
    } catch (_) {
      // Keep AppConfig.versionName fallback in tests or offline checks.
    }
  }

  Future<void> _launchUrl(String url) async {
    HapticFeedback.selectionClick();
    final channel = context.read<QsChannel>();
    final success = await channel.openUrl(url);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeMode = context.watch<ThemeCubit>().state;
    final showTileMsg = context.watch<TileMessageCubit>().state;
    final setup = context.watch<SetupBloc>().state;
    final hasSecurePermission = setup.hasPermission;

    final themeSubtitle = switch (themeMode) {
      ThemeMode.system => 'Matches device appearance',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            toolbarHeight: 60,
            title: Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList.list(
              children: [
                const SectionHeader('Appearance'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TileIcon(Symbols.contrast_rounded, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Theme', style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    themeSubtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ThemePreviewOption(
                                mode: ThemeMode.system,
                                label: 'System',
                                selected: themeMode == ThemeMode.system,
                                onTap: () => _selectTheme(context, ThemeMode.system),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ThemePreviewOption(
                                mode: ThemeMode.light,
                                label: 'Light',
                                selected: themeMode == ThemeMode.light,
                                onTap: () => _selectTheme(context, ThemeMode.light),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ThemePreviewOption(
                                mode: ThemeMode.dark,
                                label: 'Dark',
                                selected: themeMode == ThemeMode.dark,
                                onTap: () => _selectTheme(context, ThemeMode.dark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionHeader('Quick Settings'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: TileIcon(
                          Symbols.key_rounded,
                          active: hasSecurePermission,
                          size: 40,
                        ),
                        title: const Text('System settings access'),
                        subtitle: Text(
                          hasSecurePermission
                              ? 'Granted for DNS, display & debugging tiles'
                              : 'Required for Private DNS, Grayscale & Animation',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(
                              hasSecurePermission ? 'Granted' : 'Set up',
                              highlighted: hasSecurePermission,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Symbols.chevron_right_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        onTap: () => showPermissionSheet(context),
                      ),
                      const Divider(height: 1, indent: 68),
                      ListTile(
                        leading: const TileIcon(Symbols.dashboard_rounded, size: 40),
                        title: const Text('How to add tiles'),
                        subtitle: const Text('Guide for pinning Switchly tiles to Quick Settings'),
                        trailing: Icon(
                          Symbols.chevron_right_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        onTap: () => showAddTilesHelp(context),
                      ),
                      const Divider(height: 1, indent: 68),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        secondary: const TileIcon(Symbols.notifications_rounded, size: 40),
                        title: Text(
                          'Confirmation banner',
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                        ),
                        subtitle: Text(
                          'Show brief status feedback after tapping a Quick Settings tile.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        value: showTileMsg,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          context.read<TileMessageCubit>().set(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Updates'),
                const Card(child: UpdateCheckTile()),
                const SectionHeader('About'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const TileIcon(Symbols.shield_rounded, active: true, size: 40),
                        title: Text('Switchly v$_version'),
                        subtitle: const Text('100% offline · Zero data collection'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _AboutLinkTile(
                        icon: Symbols.policy_rounded,
                        title: 'Privacy Policy',
                        onTap: () => _launchUrl(AppConfig.privacyPolicyUrl),
                      ),
                      const Divider(height: 1, indent: 68),
                      _AboutLinkTile(
                        icon: Symbols.balance_rounded,
                        title: 'GPL-3.0 License',
                        onTap: () => _launchUrl(AppConfig.licenseUrl),
                      ),
                      const Divider(height: 1, indent: 68),
                      _AboutLinkTile(
                        icon: Symbols.code_rounded,
                        title: 'Source Code',
                        onTap: () => _launchUrl(AppConfig.githubRepoUrl),
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

  void _selectTheme(BuildContext context, ThemeMode mode) {
    HapticFeedback.selectionClick();
    context.read<ThemeCubit>().setThemeMode(mode);
  }
}

class _ThemePreviewOption extends StatelessWidget {
  const _ThemePreviewOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.10 : 0.05)
          : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            children: [
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: switch (mode) {
                    ThemeMode.light => const _MiniUiMock(dark: false),
                    ThemeMode.dark => const _MiniUiMock(dark: true),
                    ThemeMode.system => const Row(
                        children: [
                          Expanded(child: _MiniUiMock(dark: false, half: true)),
                          Expanded(child: _MiniUiMock(dark: true, half: true)),
                        ],
                      ),
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Symbols.check_circle_rounded, size: 14, fill: 1, color: scheme.primary),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniUiMock extends StatelessWidget {
  const _MiniUiMock({required this.dark, this.half = false});

  final bool dark;
  final bool half;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0A0B0E) : const Color(0xFFF6F7F9);
    final card = dark ? const Color(0xFF151820) : Colors.white;
    final line = dark ? const Color(0xFF282D39) : const Color(0xFFDCE0EA);
    final accent = dark ? const Color(0xFF7B83FF) : const Color(0xFF3F46E5);

    return Container(
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: half ? 4 : 7, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 7,
            width: half ? 18 : 30,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
          ),
          Container(
            height: 24,
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: line, width: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 4,
                  width: half ? 14 : 28,
                  decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 3,
                  width: half ? 10 : 18,
                  decoration: BoxDecoration(
                    color: line.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
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

class _AboutLinkTile extends StatelessWidget {
  const _AboutLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: TileIcon(icon, size: 40),
      title: Text(title),
      trailing: Icon(
        Symbols.open_in_new_rounded,
        size: 18,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      onTap: onTap,
    );
  }
}
