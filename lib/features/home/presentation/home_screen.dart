import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/platform/qs_channel.dart';
import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../calendar/data/bs_format.dart';
import '../../display/bloc/display_bloc.dart';
import '../../display/data/display_models.dart';
import '../../dns/bloc/dns_bloc.dart';
import '../../network/bloc/network_bloc.dart';
import '../../payment_qr/bloc/payment_qr_bloc.dart';
import '../../power/bloc/power_cubits.dart';
import '../../power/data/power_models.dart';
import '../../power/presentation/caffeine_screen.dart';
import '../../profiles/bloc/profiles_bloc.dart';
import '../../quick_texts/bloc/quick_texts_bloc.dart';
import '../../settings/theme_cubit.dart';
import '../../settings/tile_message_cubit.dart';
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/data/setup_repository.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';
import '../../updater/presentation/update_tile.dart';
import '../../screen_time/bloc/screen_time_bloc.dart';

enum _Category {
  all('All'),
  network('Network'),
  display('Display'),
  power('Power'),
  everyday('Everyday'),
  settings('Settings');

  const _Category(this.label);
  final String label;
}

/// Overview of every tile with live status, clean grouped sections, and quick search.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  _Category _selectedCategory = _Category.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final setup = context.watch<SetupBloc>().state;
    final hasPermission = setup.hasPermission;
    final needsSetup = setup.status == SetupStatus.ready && !hasPermission;
    final canAddTiles = canRequestAddTile(context);

    // Active status counts for the quick stats pill
    final dnsActive = context.select((DnsBloc b) => b.state.live?.isEncrypted ?? false);
    final killActive = context.select((NetworkBloc b) => b.state.killSwitchOn);
    final adbActive = context.select((NetworkBloc b) => b.state.status?.wirelessDebugging ?? false);
    final grayscaleActive = context.select((DisplayBloc b) => b.state.grayscale ?? false);
    final animActive = context.select((DisplayBloc b) => b.state.animationModified);
    final fontActive = context.select((DisplayBloc b) => b.state.fontModified);
    final caffeineActive = context.select((CaffeineCubit b) => b.state.status.on);
    final profileActive = context.select((ProfilesBloc b) => b.state.active != null);
    final screenTimeActive = context.select((ScreenTimeBloc b) => b.state.currentAppMillis > 0);

    final activeCount = [
      dnsActive,
      killActive,
      adbActive,
      grayscaleActive,
      animActive,
      fontActive,
      caffeineActive,
      profileActive,
      screenTimeActive,
    ].where((a) => a).length;

    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 68,
            title: Row(
              children: [
                Image.asset(
                  'assets/logo/logo_mark.png',
                  height: 28,
                  color: scheme.onSurface,
                  semanticLabel: 'Switchly logo',
                ),
                const SizedBox(width: 10),
                Text(
                  'Switchly',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                icon: Icon(
                  isDark ? Symbols.light_mode_rounded : Symbols.dark_mode_rounded,
                  size: 22,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<ThemeCubit>().toggleTheme();
                },
              ),
              IconButton(
                tooltip: 'How to add tiles',
                icon: const Icon(Symbols.help_outline_rounded, size: 22),
                onPressed: () => showAddTilesHelp(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
            sliver: SliverList.list(
              children: [
                // In-app update alert banner (shown when an update is available)
                const UpdateNotificationBanner(),

                // Quick Dashboard Header
                _SystemStatusBar(
                  hasPermission: hasPermission,
                  activeCount: activeCount,
                  onSetupTap: () => showPermissionSheet(context),
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search toggles (DNS, battery, caffeine...)',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Symbols.search_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Symbols.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                ),

                // Category filter chips (when not actively searching)
                if (!isSearching) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (final cat in _Category.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryPill(
                              label: cat.label,
                              selected: _selectedCategory == cat,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = cat);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Setup banner (if permission still needed)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: needsSetup && !isSearching
                      ? const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: _SetupBanner(),
                        )
                      : const SizedBox(width: double.infinity),
                ),

                // Tile Groups
                if (isSearching)
                  _buildSearchResults(context, canAddTiles)
                else
                  _buildCategorizedSections(context, canAddTiles),

                const SizedBox(height: 36),
                const _PrivacyFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, bool canAddTiles) {
    final matches = _filterTiles(_searchQuery, context, canAddTiles);
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Symbols.search_off_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text('No toggles match "$_searchQuery"', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text('Clear search'),
              ),
            ],
          ),
        ),
      );
    }
    return _GroupedSection(
      title: 'Search results',
      children: matches,
    );
  }

  Widget _buildCategorizedSections(BuildContext context, bool canAddTiles) {
    final showAll = _selectedCategory == _Category.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAll || _selectedCategory == _Category.network)
          const _GroupedSection(
            title: 'Network',
            subtitle: 'Encrypted DNS, kill switch and wireless debugging',
            children: [
              _PrivateDnsTileRow(),
              _KillSwitchTileRow(),
              _WirelessDebuggingTileRow(),
            ],
          ),
        if (showAll || _selectedCategory == _Category.display)
          const _GroupedSection(
            title: 'Display',
            subtitle: 'Focus mode, transition scales and text sizing',
            children: [
              _GrayscaleTileRow(),
              _AnimationTileRow(),
              _FontSizeTileRow(),
            ],
          ),
        if (showAll || _selectedCategory == _Category.power)
          const _GroupedSection(
            title: 'Power',
            subtitle: 'Keep screen awake and live battery diagnostics',
            children: [
              _CaffeineTileRow(),
              _BatteryTileRow(),
            ],
          ),
        if (showAll || _selectedCategory == _Category.everyday)
          _GroupedSection(
            title: 'Everyday',
            subtitle: 'Quick tools accessible from any screen',
            children: [
              const _BsDateTileRow(),
              const _AppScreenTimeTileRow(),
              _TileRow(
                tile: qrScannerTile,
                status: 'Scan any code · Offline',
                active: false,
                onTap: () => context.read<QsChannel>().openQrScanner(),
                trailing: IconButton(
                  tooltip: 'Add to Quick Settings',
                  icon: const Icon(Symbols.add_circle_outline_rounded, size: 22),
                  onPressed: () =>
                      canAddTiles ? requestAddTile(context, qrScannerTile) : showAddTilesHelp(context),
                ),
              ),
              _TileRow(
                tile: paymentQrTile,
                status: _countLabel(context.select((PaymentQrBloc b) => b.state.qrs.length), 'QR code'),
                active: false,
                onTap: () => Navigator.of(context).pushNamed(AppRouter.paymentQr),
                trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
              ),
              _TileRow(
                tile: quickTextsTile,
                status: _countLabel(context.select((QuickTextsBloc b) => b.state.texts.length), 'text'),
                active: false,
                onTap: () => Navigator.of(context).pushNamed(AppRouter.quickTexts),
                trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
              ),
              const _ProfilesTileRow(),
            ],
          ),
        if (showAll || _selectedCategory == _Category.settings)
          const _GroupedSection(
            title: 'Preferences',
            children: [
              _ThemePreferenceTileRow(),
              _TileMessageTileRow(),
              UpdateCheckTile(),
            ],
          ),
      ],
    );
  }

  List<Widget> _filterTiles(String query, BuildContext context, bool canAddTiles) {
    final list = <Widget>[];

    bool matches(String name, String desc) =>
        name.toLowerCase().contains(query) || desc.toLowerCase().contains(query);

    if (matches('private dns', 'encrypted network doh provider cycle')) {
      list.add(const _PrivateDnsTileRow());
    }
    if (matches('internet kill switch', 'block traffic disconnect drop vpn')) {
      list.add(const _KillSwitchTileRow());
    }
    if (matches('wireless debugging', 'adb wifi port developer')) {
      list.add(const _WirelessDebuggingTileRow());
    }
    if (matches('grayscale', 'black and white monochrome display color')) {
      list.add(const _GrayscaleTileRow());
    }
    if (matches('animation speed', 'transition window scale fast animator')) {
      list.add(const _AnimationTileRow());
    }
    if (matches('font size', 'text scale large readability font')) {
      list.add(const _FontSizeTileRow());
    }
    if (matches('caffeine', 'stay awake screen timeout display lock sleep')) {
      list.add(const _CaffeineTileRow());
    }
    if (matches('battery', 'charging wattage power temperature level')) {
      list.add(const _BatteryTileRow());
    }
    if (matches('nepali date', 'calendar bikram sambat bs ad')) {
      list.add(const _BsDateTileRow());
    }
    if (matches('scan qr', 'camera scanner barcode offline')) {
      list.add(_TileRow(
        tile: qrScannerTile,
        status: 'Scan any code · Offline',
        active: false,
        onTap: () => context.read<QsChannel>().openQrScanner(),
        trailing: IconButton(
          tooltip: 'Add to Quick Settings',
          icon: const Icon(Symbols.add_circle_outline_rounded, size: 22),
          onPressed: () =>
              canAddTiles ? requestAddTile(context, qrScannerTile) : showAddTilesHelp(context),
        ),
      ));
    }
    if (matches('payment qr', 'esewa khalti fonepay wallet lock screen')) {
      list.add(_TileRow(
        tile: paymentQrTile,
        status: _countLabel(context.select((PaymentQrBloc b) => b.state.qrs.length), 'QR code'),
        active: false,
        onTap: () => Navigator.of(context).pushNamed(AppRouter.paymentQr),
        trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
      ));
    }
    if (matches('quick texts', 'clipboard snippets paste copy text')) {
      list.add(_TileRow(
        tile: quickTextsTile,
        status: _countLabel(context.select((QuickTextsBloc b) => b.state.texts.length), 'text'),
        active: false,
        onTap: () => Navigator.of(context).pushNamed(AppRouter.quickTexts),
        trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
      ));
    }
    if (matches('profiles', 'preset focus bundle toggle apply')) {
      list.add(const _ProfilesTileRow());
    }
    if (matches('theme appearance dark light mode', 'appearance dark mode theme colors')) {
      list.add(const _ThemePreferenceTileRow());
    }
    if (matches('preferences message', 'show message after tap toast notify')) {
      list.add(const _TileMessageTileRow());
    }
    if (matches('check for updates', 'github releases new version download install upgrade')) {
      list.add(const UpdateCheckTile());
    }
    if (matches('screen time app usage timer', 'screen time track app usage digital wellbeing')) {
      list.add(const _AppScreenTimeTileRow());
    }

    return list;
  }
}

/// Compact status bar showing system access readiness and active toggles count.
class _SystemStatusBar extends StatelessWidget {
  const _SystemStatusBar({
    required this.hasPermission,
    required this.activeCount,
    required this.onSetupTap,
  });

  final bool hasPermission;
  final int activeCount;
  final VoidCallback onSetupTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: hasPermission ? null : onSetupTap,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasPermission
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : scheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: hasPermission
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : scheme.error.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasPermission ? Symbols.check_circle_rounded : Symbols.error_outline_rounded,
                    size: 14,
                    color: hasPermission ? const Color(0xFF10B981) : scheme.error,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hasPermission ? 'System Access Active' : 'Setup Required',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: hasPermission ? const Color(0xFF10B981) : scheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            activeCount == 0 ? 'All tiles standby' : '$activeCount active',
            style: theme.textTheme.labelSmall?.copyWith(
              color: activeCount > 0 ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal category filter pill.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean container holding a group of related tiles with subtle hairlines.
class _GroupedSection extends StatelessWidget {
  const _GroupedSection({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, subtitle: subtitle),
        Material(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 74,
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Single tile row inside a grouped section.
class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.tile,
    required this.status,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final TileDefinition tile;
  final String status;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              TileIcon(tile.icon, active: active, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        status,
                        key: ValueKey(status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: active ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusPill(active ? 'On' : 'Off', highlighted: active),
                    const SizedBox(width: 4),
                    Icon(
                      Symbols.chevron_right_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
  }
}

class _SetupBanner extends StatelessWidget {
  const _SetupBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppTheme.brandGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.key_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Complete one-time setup',
                style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Grant system settings permission via ADB to enable Private DNS, animations and display controls.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88), height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3730A3),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => showPermissionSheet(context),
            child: const Text('Set up now'),
          ),
        ],
      ),
    );
  }
}

class _PrivateDnsTileRow extends StatelessWidget {
  const _PrivateDnsTileRow();

  @override
  Widget build(BuildContext context) {
    final dns = context.watch<DnsBloc>().state;
    final active = dns.live?.isEncrypted ?? false;
    return _TileRow(
      tile: privateDnsTile,
      status: active ? dns.liveLabel : 'Encrypted DNS is ${dns.liveLabel.toLowerCase()}',
      active: active,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.dns),
    );
  }
}

class _KillSwitchTileRow extends StatelessWidget {
  const _KillSwitchTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NetworkBloc>().state;
    final on = state.killSwitchOn;
    final allowed = state.allowedApps.length;
    return _TileRow(
      tile: killSwitchTile,
      status: on ? (allowed == 0 ? 'Internet blocked' : 'Blocked · $allowed allowed') : 'Internet online',
      active: on,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.killSwitch),
    );
  }
}

class _WirelessDebuggingTileRow extends StatelessWidget {
  const _WirelessDebuggingTileRow();

  @override
  Widget build(BuildContext context) {
    final status = context.select((NetworkBloc bloc) => bloc.state.status);
    final on = status?.wirelessDebugging ?? false;

    Future<void> toggle() async {
      if (status == null || !status.wirelessSupported) return;
      if (!status.devOptions) {
        await context.read<SetupRepository>().openDeveloperOptions();
        return;
      }
      if (!context.read<SetupBloc>().state.hasPermission) {
        await showPermissionSheet(context);
        return;
      }
      HapticFeedback.selectionClick();
      context.read<NetworkBloc>().add(WirelessDebuggingSet(!on));
    }

    Future<void> copyAddress() async {
      await Clipboard.setData(ClipboardData(text: 'adb connect ${status!.address}'));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied adb connect ${status.address}')));
    }

    return _TileRow(
      tile: wirelessDebuggingTile,
      status: switch (status) {
        null => '—',
        _ when !status.wirelessSupported => 'Needs Android 11 or newer',
        _ when !status.devOptions => 'Turn on Developer options first',
        _ when !on => 'Off',
        _ => status.address ?? 'Waiting for Wi-Fi',
      },
      active: on,
      onTap: toggle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (on && (status?.hasPort ?? false))
            IconButton(
              tooltip: 'Copy adb connect',
              icon: const Icon(Symbols.content_copy_rounded, size: 18),
              onPressed: copyAddress,
            ),
          if (status?.wirelessSupported ?? false)
            status!.devOptions
                ? Switch(value: on, onChanged: (_) => toggle())
                : Icon(
                    Symbols.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
        ],
      ),
    );
  }
}

class _GrayscaleTileRow extends StatelessWidget {
  const _GrayscaleTileRow();

  @override
  Widget build(BuildContext context) {
    final on = context.select((DisplayBloc bloc) => bloc.state.grayscale ?? false);

    void toggle() {
      if (!context.read<SetupBloc>().state.hasPermission) {
        showPermissionSheet(context);
        return;
      }
      HapticFeedback.selectionClick();
      context.read<DisplayBloc>().add(GrayscaleSet(!on));
    }

    return _TileRow(
      tile: grayscaleTile,
      status: on ? 'Monochrome active' : 'Full colour display',
      active: on,
      onTap: toggle,
      trailing: Switch(value: on, onChanged: (_) => toggle()),
    );
  }
}

class _AnimationTileRow extends StatelessWidget {
  const _AnimationTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DisplayBloc>().state;
    final speed = state.speed;
    return _TileRow(
      tile: animationSpeedTile,
      status: switch (state.scales) {
        null => '—',
        _ when speed == null => 'Custom scales active',
        _ when sameSpeed(speed, 0) => 'Animations disabled',
        _ => '${speedLabel(speed)} · ${speedDescription(speed)}',
      },
      active: state.animationModified,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.animation),
    );
  }
}

class _FontSizeTileRow extends StatelessWidget {
  const _FontSizeTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DisplayBloc>().state;
    final scale = state.fontScale;
    return _TileRow(
      tile: fontSizeTile,
      status: scale == null ? '—' : '${fontLabel(scale)} · ${fontDescription(scale)}',
      active: state.fontModified,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.fontSize),
    );
  }
}

class _CaffeineTileRow extends StatelessWidget {
  const _CaffeineTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CaffeineCubit>().state;
    final on = state.status.on;
    final cubit = context.read<CaffeineCubit>();
    return _TileRow(
      tile: caffeineTile,
      status: on ? caffeineDetail(context, state.status) : 'Normal sleep timeout',
      active: on,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.caffeine),
      trailing: Switch(
        value: on,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          v ? cubit.start(state.config.minutes.first) : cubit.stop();
        },
      ),
    );
  }
}

class _BatteryTileRow extends StatelessWidget {
  const _BatteryTileRow();

  @override
  Widget build(BuildContext context) {
    final battery = context.watch<BatteryCubit>().state;
    final canAdd = canRequestAddTile(context);
    return _TileRow(
      tile: batteryTile,
      status: battery == null ? '—' : batterySummary(battery),
      active: battery?.plugged ?? false,
      onTap: () => canAdd ? requestAddTile(context, batteryTile) : showAddTilesHelp(context),
      trailing: Icon(
        Symbols.add_circle_outline_rounded,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}

class _BsDateTileRow extends StatelessWidget {
  const _BsDateTileRow();

  @override
  Widget build(BuildContext context) {
    final nepali = context.watch<BsScriptCubit>().state;
    final today = DateTime.now().toNepaliDateTime();
    return _TileRow(
      tile: bsDateTile,
      status: '${BsFormat.weekday(today, nepali)}, ${BsFormat.date(today, nepali)}',
      active: true,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.calendar),
      trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
    );
  }
}

class _AppScreenTimeTileRow extends StatelessWidget {
  const _AppScreenTimeTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ScreenTimeBloc>().state;
    final canAddTiles = canRequestAddTile(context);
    final hasApp = state.config != null;
    final status = hasApp
        ? '${state.config!.appName} · ${state.currentAppFormatted}'
        : (state.hasPermission ? 'Select an app to track' : 'Usage permission required');
    final active = hasApp && state.currentAppMillis > 0;

    return _TileRow(
      tile: appScreenTimeTile,
      status: status,
      active: active,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.appScreenTime),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add to Quick Settings',
            icon: const Icon(Symbols.add_circle_outline_rounded, size: 22),
            onPressed: () => canAddTiles
                ? requestAddTile(context, appScreenTimeTile)
                : showAddTilesHelp(context),
          ),
          const Icon(Symbols.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

class _ProfilesTileRow extends StatelessWidget {
  const _ProfilesTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfilesBloc>().state;
    final active = state.active;
    return _TileRow(
      tile: profilesTile,
      status: active != null ? '${active.name} is active' : _countLabel(state.profiles.length, 'profile'),
      active: active != null,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.profiles),
      trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
    );
  }
}

class _TileMessageTileRow extends StatelessWidget {
  const _TileMessageTileRow();

  @override
  Widget build(BuildContext context) {
    final show = context.watch<TileMessageCubit>().state;
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: const TileIcon(Symbols.notifications_rounded, size: 44),
      title: Text(
        'Show confirmation message',
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Displays brief banner feedback when toggling tiles from Quick Settings.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      value: show,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        context.read<TileMessageCubit>().set(v);
      },
    );
  }
}

class _ThemePreferenceTileRow extends StatelessWidget {
  const _ThemePreferenceTileRow();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final label = switch (themeMode) {
      ThemeMode.dark => 'Dark (Default)',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'Follow system',
    };

    return InkWell(
      onTap: () => _showThemePicker(context, themeMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const TileIcon(Symbols.contrast_rounded, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (themeMode) {
                      ThemeMode.dark => Symbols.dark_mode_rounded,
                      ThemeMode.light => Symbols.light_mode_rounded,
                      ThemeMode.system => Symbols.settings_suggest_rounded,
                    },
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    switch (themeMode) {
                      ThemeMode.dark => 'Dark',
                      ThemeMode.light => 'Light',
                      ThemeMode.system => 'Auto',
                    },
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Symbols.unfold_more_rounded, size: 16, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose appearance',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _ThemeOption(
                  icon: Symbols.dark_mode_rounded,
                  title: 'Dark theme',
                  subtitle: 'Default · Tailored for battery and night comfort',
                  selected: current == ThemeMode.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 8),
                _ThemeOption(
                  icon: Symbols.light_mode_rounded,
                  title: 'Light theme',
                  subtitle: 'Bright and high contrast',
                  selected: current == ThemeMode.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<ThemeCubit>().setThemeMode(ThemeMode.light);
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 8),
                _ThemeOption(
                  icon: Symbols.settings_suggest_rounded,
                  title: 'Follow system',
                  subtitle: "Matches your device's display setting",
                  selected: current == ThemeMode.system,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<ThemeCubit>().setThemeMode(ThemeMode.system);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.1) : scheme.surfaceContainerHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Symbols.check_circle_rounded, color: scheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.shield_rounded, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              '100% Offline · Zero Data Collection',
              style: theme.textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Switchly v0.0.3 · GPL-3.0 License',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

String batterySummary(BatteryStatus b) => [
      '${b.level}%',
      if (b.plugged && b.full)
        'Full'
      else if (b.plugged)
        b.watts != null ? 'Charging ${b.watts!.toStringAsFixed(1)} W' : 'Charging',
      if (b.temperature != null) '${b.temperature!.toStringAsFixed(1)}°C',
    ].join(' · ');

String _countLabel(int count, String noun) => switch (count) {
      0 => 'No ${noun}s saved',
      1 => '1 $noun saved',
      _ => '$count ${noun}s saved',
    };
