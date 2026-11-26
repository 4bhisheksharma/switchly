import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../app/router.dart';
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
import '../../public_mode/bloc/public_mode_bloc.dart';
import '../../public_mode/presentation/widgets/hand_over_card.dart';
import '../../quick_texts/bloc/quick_texts_bloc.dart';
import '../../reminders/bloc/reminders_bloc.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../screen_time/bloc/screen_time_bloc.dart';
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/data/setup_repository.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';
import '../../updater/presentation/update_tile.dart';
import '../../volume/bloc/volume_bloc.dart';

enum _Category {
  all('All'),
  network('Network'),
  display('Display'),
  power('Power'),
  everyday('Everyday');

  const _Category(this.label);
  final String label;
}

/// Overview of every tile with live status, clean grouped sections, and quick search.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenCalendarTab,
    this.onOpenPayQrTab,
    this.onOpenRemindersTab,
  });

  final VoidCallback? onOpenCalendarTab;
  final VoidCallback? onOpenPayQrTab;
  final VoidCallback? onOpenRemindersTab;

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

    final dnsActive = context.select((DnsBloc b) => b.state.live?.isEncrypted ?? false);
    final adbActive = context.select((NetworkBloc b) => b.state.status?.wirelessDebugging ?? false);
    final grayscaleActive = context.select((DisplayBloc b) => b.state.grayscale ?? false);
    final animActive = context.select((DisplayBloc b) => b.state.animationModified);
    final fontActive = context.select((DisplayBloc b) => b.state.fontModified);
    final caffeineActive = context.select((CaffeineCubit b) => b.state.status.on);
    final profileActive = context.select((ProfilesBloc b) => b.state.active != null);
    final screenTimeActive = context.select((ScreenTimeBloc b) => b.state.currentAppMillis > 0);
    final publicActive = context.select((PublicModeBloc b) => b.state.active);

    final activeCount = [
      dnsActive,
      adbActive,
      grayscaleActive,
      animActive,
      fontActive,
      caffeineActive,
      profileActive,
      screenTimeActive,
      publicActive,
    ].where((bool a) => a).length;

    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 60,
            title: Row(
              children: [
                Image.asset(
                  'assets/logo/logo_mark.png',
                  height: 26,
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
                if (activeCount > 0) ...[
                  const SizedBox(width: 10),
                  StatusPill('$activeCount active', highlighted: true),
                ],
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'How to add tiles',
                icon: const Icon(Symbols.help_outline_rounded, size: 22),
                onPressed: () => showAddTilesHelp(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
            sliver: SliverList.list(
              children: [
                const UpdateNotificationBanner(),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      filled: false,
                      hintText: 'Search tiles & tools...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        Symbols.search_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Symbols.close_rounded, size: 18),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                ),

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

                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: needsSetup && !isSearching
                      ? const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: _SetupBanner(),
                        )
                      : const SizedBox(width: double.infinity),
                ),

                if (!isSearching) ...[
                  const SizedBox(height: 14),
                  const HandOverCard(),
                ],

                if (isSearching)
                  _buildSearchResults(context, canAddTiles)
                else
                  _buildCategorizedSections(context, canAddTiles),
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
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text('No tools match "$_searchQuery"', style: Theme.of(context).textTheme.titleSmall),
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
    final publicModeState = context.watch<PublicModeBloc>().state;
    final hiddenTiles =
        publicModeState.active ? publicModeState.config.hiddenTiles : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAll || _selectedCategory == _Category.network)
          _GroupedSection(
            title: 'Network',
            subtitle: 'Encrypted DNS and wireless debugging',
            children: [
              const _PrivateDnsTileRow(),
              if (!hiddenTiles.contains('wireless_debugging')) const _WirelessDebuggingTileRow(),
            ],
          ),
        if (showAll || _selectedCategory == _Category.display)
          _GroupedSection(
            title: 'Display',
            subtitle: 'Focus mode, transition scales, text sizing and screenshot',
            children: [
              const _GrayscaleTileRow(),
              const _AnimationTileRow(),
              const _FontSizeTileRow(),
              if (!hiddenTiles.contains('screenshot')) const _ScreenshotTileRow(),
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
              const _PublicModeTileRow(),
              _BsDateTileRow(onTap: widget.onOpenCalendarTab),
              _RemindersTileRow(onTap: widget.onOpenRemindersTab),
              if (!hiddenTiles.contains('volume')) const _VolumeTileRow(),
              const _AppScreenTimeTileRow(),
              if (!hiddenTiles.contains('qr_scanner'))
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
              if (!hiddenTiles.contains('payment_qr'))
                _TileRow(
                  tile: paymentQrTile,
                  status: _countLabel(context.select((PaymentQrBloc b) => b.state.qrs.length), 'QR code'),
                  active: false,
                  onTap: widget.onOpenPayQrTab ??
                      () => Navigator.of(context).pushNamed(AppRouter.paymentQr),
                  trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
                ),
              if (!hiddenTiles.contains('quick_texts'))
                _TileRow(
                  tile: quickTextsTile,
                  status: _countLabel(context.select((QuickTextsBloc b) => b.state.texts.length), 'text'),
                  active: false,
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.quickTexts),
                  trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
                ),
              if (!hiddenTiles.contains('profiles')) const _ProfilesTileRow(),
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
    if (matches('screenshot', 'take screen capture snapshot record display')) {
      list.add(const _ScreenshotTileRow());
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
      list.add(_BsDateTileRow(onTap: widget.onOpenCalendarTab));
    }
    if (matches('reminders notification alert schedule alarm todo',
        'push notification date time reminder schedule repeat')) {
      list.add(_RemindersTileRow(onTap: widget.onOpenRemindersTab));
    }
    if (matches('volume slider loudness sound audio ring media mute silent',
        'volume slider control loudness media ringtone notification alarm sound audio levels')) {
      list.add(const _VolumeTileRow());
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
        onTap: widget.onOpenPayQrTab ?? () => Navigator.of(context).pushNamed(AppRouter.paymentQr),
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
    if (matches('screen time app usage timer', 'screen time track app usage digital wellbeing')) {
      list.add(const _AppScreenTimeTileRow());
    }
    if (matches('public mode hand phone over guest borrow lock private apps',
        'prepare device temporary profile block private apps hide tiles')) {
      list.add(const _PublicModeTileRow());
    }

    return list;
  }
}

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
    final dark = theme.brightness == Brightness.dark;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: dark ? 0.18 : 0.10)
          : scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? scheme.primary.withValues(alpha: 0.55) : scheme.outlineVariant,
          width: selected ? 1.2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, subtitle: subtitle),
        Material(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 70,
                    color: scheme.outlineVariant,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            TileIcon(tile.icon, active: active, size: 42),
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
                    child: Align(
                      key: ValueKey(status),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: active ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
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
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TileIcon(Symbols.key_rounded, active: true, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One-time permission required',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grant WRITE_SECURE_SETTINGS via ADB or Shizuku to control Private DNS and display settings directly from quick tiles.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => showPermissionSheet(context),
                  child: const Text('Set up now'),
                ),
              ],
            ),
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

class _ScreenshotTileRow extends StatelessWidget {
  const _ScreenshotTileRow();

  @override
  Widget build(BuildContext context) {
    return _TileRow(
      tile: screenshotTile,
      status: '1-tap screen capture from Quick Settings',
      active: true,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.screenshot),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add to Quick Settings',
            icon: const Icon(Symbols.add_circle_outline_rounded, size: 22),
            onPressed: () => canRequestAddTile(context)
                ? requestAddTile(context, screenshotTile)
                : showAddTilesHelp(context),
          ),
          const Icon(Symbols.chevron_right_rounded, size: 20),
        ],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied adb connect ${status.address}')),
      );
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
  const _BsDateTileRow({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nepali = context.watch<BsScriptCubit>().state;
    final today = DateTime.now().toNepaliDateTime();
    return _TileRow(
      tile: bsDateTile,
      status: '${BsFormat.weekday(today, nepali)}, ${BsFormat.date(today, nepali)}',
      active: true,
      onTap: onTap ?? () => Navigator.of(context).pushNamed(AppRouter.calendar),
      trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
    );
  }
}

class _VolumeTileRow extends StatelessWidget {
  const _VolumeTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VolumeBloc>().state;
    final music = state.snapshot.music;
    final ringer = state.snapshot.ringerMode;
    final status = 'Media: ${music.percent}% · ${ringer.label}';

    return _TileRow(
      tile: volumeTile,
      status: status,
      active: !music.isMuted,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.volume),
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
    final count = state.slots.length;
    final status = count == 0
        ? (state.hasPermission ? 'Track up to 4 apps in Quick Settings' : 'Usage permission required')
        : (count == 1
            ? '${state.slots.first.appName} · ${state.timeForSlot(state.slots.first.slot).formatted}'
            : '$count apps tracked (${state.slots.map((s) => s.appName).join(', ')})');
    final active = count > 0;

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

class _PublicModeTileRow extends StatelessWidget {
  const _PublicModeTileRow();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PublicModeBloc>().state;
    final canAddTiles = canRequestAddTile(context);
    final status = state.active
        ? (state.endsAt > 0 ? '${state.formattedRemainingTime} left' : 'Active')
        : (state.config.blockedPackages.isEmpty
            ? 'Tap to hand over'
            : '${state.config.blockedPackages.length} apps locked');

    return _TileRow(
      tile: publicModeTile,
      status: status,
      active: state.active,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.publicMode),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add to Quick Settings',
            icon: const Icon(Symbols.add_circle_outline_rounded, size: 22),
            onPressed: () =>
                canAddTiles ? requestAddTile(context, publicModeTile) : showAddTilesHelp(context),
          ),
          const Icon(Symbols.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

class _RemindersTileRow extends StatelessWidget {
  const _RemindersTileRow({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RemindersBloc>().state;
    final canAddTiles = canRequestAddTile(context);
    final next = state.nextUpcoming;
    final count = state.upcomingCount;

    final status = next == null
        ? 'No upcoming reminders'
        : (count == 1
            ? '${next.title} · ${formatReminderDateTime(context, next.scheduledAt)}'
            : '${next.title} · ${formatReminderDateTime(context, next.scheduledAt)} (+${count - 1})');

    return _TileRow(
      tile: remindersTile,
      status: status,
      active: count > 0,
      onTap: onTap ?? () => Navigator.of(context).pushNamed(AppRouter.reminders),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add to Quick Settings',
            icon: const Icon(Symbols.add_circle_outline_rounded, size: 22),
            onPressed: () =>
                canAddTiles ? requestAddTile(context, remindersTile) : showAddTilesHelp(context),
          ),
          const Icon(Symbols.chevron_right_rounded, size: 20),
        ],
      ),
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
