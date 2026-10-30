import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/select_chip.dart';
import '../bloc/public_mode_bloc.dart';
import '../data/public_mode_models.dart';
import 'widgets/public_mode_pin_dialogs.dart';

class PublicModeScreen extends StatefulWidget {
  const PublicModeScreen({super.key});

  @override
  State<PublicModeScreen> createState() => _PublicModeScreenState();
}

class _PublicModeScreenState extends State<PublicModeScreen> {
  Timer? _countdownTimer;

  static const _timeoutOptions = <int, String>{
    2: '2 min',
    5: '5 min',
    10: '10 min',
    15: '15 min',
    30: '30 min',
    60: '1 hour',
    0: 'No limit',
  };

  static const _hideableTiles = <String, ({String label, String desc, IconData icon})>{
    'payment_qr': (
      label: 'Payment QR',
      desc: 'Hide your payment & receiving codes',
      icon: Symbols.qr_code_2_rounded,
    ),
    'quick_texts': (
      label: 'Quick Texts',
      desc: 'Hide sensitive clipboard snippets',
      icon: Symbols.content_paste_rounded,
    ),
    'wireless_debugging': (
      label: 'Wireless Debugging',
      desc: 'Hide developer ADB controls',
      icon: Symbols.developer_mode_rounded,
    ),
    'profiles': (
      label: 'Profiles',
      desc: 'Hide profile switching tile',
      icon: Symbols.tune_rounded,
    ),
    'kill_switch': (
      label: 'Internet Kill Switch',
      desc: 'Hide network kill switch',
      icon: Symbols.public_off_rounded,
    ),
    'qr_scanner': (
      label: 'Scan QR',
      desc: 'Hide camera QR scanner',
      icon: Symbols.qr_code_scanner_rounded,
    ),
  };

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final state = context.read<PublicModeBloc>().state;
        if (state.active && state.endsAt > 0) {
          setState(() {});
          if (state.remainingSeconds <= 0) {
            context.read<PublicModeBloc>().add(const PublicModeRefreshed());
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateConfig(PublicModeConfig newConfig) {
    context.read<PublicModeBloc>().add(PublicModeConfigUpdated(newConfig));
  }

  void _openAppPicker(BuildContext context, PublicModeState state) {
    if (state.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot modify blocked apps while Public Mode is active. Exit Public Mode first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetCtx) => _AppPickerSheet(
        initialBlocked: state.config.blockedPackages,
        apps: state.launchableApps,
        onSaved: (selected) {
          _updateConfig(state.config.copyWith(blockedPackages: selected));
        },
      ),
    );
  }

  Future<void> _activatePublicMode(BuildContext context, PublicModeState state) async {
    final bloc = context.read<PublicModeBloc>();
    final channel = context.read<QsChannel>();
    final repository = PublicModeRepository(channel);

    if (state.config.pin == null || state.config.pin!.isEmpty) {
      final created = await showPublicModePinSetupDialog(
        context,
        repository: repository,
        onSaved: (newPin, recoveryAnswer) {
          _updateConfig(state.config.copyWith(
            pin: newPin,
            recoveryAnswer: recoveryAnswer,
          ));
        },
      );
      if (!created) return;
    }
    bloc.add(const PublicModeActivateRequested());
  }

  Future<void> _exitPublicMode(BuildContext context, PublicModeState state) async {
    final bloc = context.read<PublicModeBloc>();
    final channel = context.read<QsChannel>();
    final repository = PublicModeRepository(channel);

    if (state.config.pin != null && state.config.pin!.isNotEmpty) {
      await showPublicModePinVerifyDialog(
        context,
        expectedPin: state.config.pin!,
        repository: repository,
        recoveryAnswer: state.config.recoveryAnswer,
        endsAt: state.endsAt,
        onVerified: () async {
          bloc.add(const PublicModeDeactivateRequested());
        },
      );
    } else {
      bloc.add(const PublicModeDeactivateRequested());
    }
  }

  Future<void> _setOrChangePin(BuildContext context, PublicModeState state) async {
    if (state.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot change PIN while Public Mode is active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final channel = context.read<QsChannel>();
    final repository = PublicModeRepository(channel);

    await showPublicModePinSetupDialog(
      context,
      repository: repository,
      onSaved: (newPin, recoveryAnswer) {
        _updateConfig(state.config.copyWith(
          pin: newPin,
          recoveryAnswer: recoveryAnswer,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exit PIN updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<PublicModeBloc>().state;
    final config = state.config;
    final isActive = state.active;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          HeroStatusCard(
            icon: Symbols.shield_person_rounded,
            label: 'TEMPORARY PROFILE',
            value: isActive ? 'Public Mode is Active' : 'Ready to Hand Over',
            detail: isActive
                ? (state.endsAt > 0
                    ? 'Auto-restoring in ${state.formattedRemainingTime}'
                    : 'Active until turned off')
                : 'Locks private apps, hides sensitive tiles, and restores automatically.',
            active: isActive,
            busy: state.loading,
            action: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isActive ? Colors.white : scheme.primary,
                foregroundColor: isActive ? Colors.red.shade900 : scheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(isActive ? Symbols.lock_open_rounded : Symbols.front_hand_rounded),
              label: Text(
                isActive ? 'Exit & Restore Previous Profile' : 'Hand my phone over now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                if (isActive) {
                  _exitPublicMode(context, state);
                } else {
                  _activatePublicMode(context, state);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Locked notice banner if active
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Symbols.lock_rounded, size: 20, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings are locked while Public Mode is active. To change blocked apps or options, exit Public Mode first.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Permissions warning card if needed
          if (!state.hasUsageAccess ||
              !state.canDrawOverlays ||
              (state.isXiaomiDevice && !state.hasMiuiPopupPermission) ||
              !state.isIgnoringBattery) ...[
            _PermissionWarningCard(
              hasUsage: state.hasUsageAccess,
              hasOverlay: state.canDrawOverlays,
              hasDnd: state.hasDndAccess,
              isXiaomi: state.isXiaomiDevice,
              hasMiuiPopup: state.hasMiuiPopupPermission,
              isIgnoringBattery: state.isIgnoringBattery,
              onRefresh: () =>
                  context.read<PublicModeBloc>().add(const PublicModePermissionsChecked()),
            ),
            const SizedBox(height: 20),
          ],

          // 1. Automatic Timeout
          const SectionHeader(
            'Automatic Timeout',
            subtitle: 'Automatically ends and restores your previous profile when time runs out.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _timeoutOptions.entries)
                SelectChip(
                  label: entry.value,
                  selected: config.timeoutMinutes == entry.key,
                  onTap: isActive
                      ? () {}
                      : () => _updateConfig(config.copyWith(timeoutMinutes: entry.key)),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Private Apps to Block
          SectionHeader(
            'Private Apps to Block',
            subtitle: '${config.blockedPackages.length} apps selected to intercept with lock overlay.',
            trailing: isActive
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.lock_rounded, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : TextButton.icon(
                    icon: const Icon(Symbols.add_circle_outline_rounded, size: 18),
                    label: const Text('Select Apps'),
                    onPressed: () => _openAppPicker(context, state),
                  ),
          ),
          if (config.blockedPackages.isEmpty)
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Symbols.apps_rounded, color: scheme.primary),
                title: const Text('No apps selected yet'),
                subtitle: const Text('Tap to choose apps like Photos, WhatsApp, or Banking apps to block.'),
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: isActive ? null : () => _openAppPicker(context, state),
              ),
            )
          else ...[
            _BlockedAppsPreview(
              blockedPackages: config.blockedPackages,
              launchableApps: state.launchableApps,
              onManageTap: isActive ? null : () => _openAppPicker(context, state),
            ),
          ],
          const SizedBox(height: 24),

          // 3. Hide from Switchly Home Surface
          const SectionHeader(
            'Hide from Switchly Home',
            subtitle: 'These items disappear from Switchly’s home dashboard while Public Mode is on.',
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                for (final entry in _hideableTiles.entries) ...[
                  CheckboxListTile(
                    value: config.hiddenTiles.contains(entry.key),
                    secondary: Icon(entry.value.icon, color: scheme.primary),
                    title: Text(entry.value.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(entry.value.desc),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onChanged: isActive
                        ? null
                        : (checked) {
                            final updated = List<String>.from(config.hiddenTiles);
                            if (checked == true) {
                              if (!updated.contains(entry.key)) updated.add(entry.key);
                            } else {
                              updated.remove(entry.key);
                            }
                            _updateConfig(config.copyWith(hiddenTiles: updated));
                          },
                  ),
                  if (entry.key != _hideableTiles.keys.last)
                    Divider(height: 1, indent: 64, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Supported System Protection Settings
          const SectionHeader(
            'Device Protection Settings',
            subtitle: 'Settings applied when handing your phone over, restored automatically afterward.',
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                SwitchListTile(
                  value: config.enableDnd,
                  secondary: const Icon(Symbols.do_not_disturb_on_rounded),
                  title: const Text('Do Not Disturb', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Hide sensitive incoming notifications, previews, and chat alerts.'),
                  onChanged: isActive
                      ? null
                      : (val) => _updateConfig(config.copyWith(enableDnd: val)),
                ),
                Divider(height: 1, indent: 64, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                SwitchListTile(
                  value: config.enableGrayscale,
                  secondary: const Icon(Symbols.contrast_rounded),
                  title: const Text('Grayscale display', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Convert screen to monochrome to reduce phone browsing interest.'),
                  onChanged: isActive
                      ? null
                      : (val) => _updateConfig(config.copyWith(enableGrayscale: val)),
                ),
                Divider(height: 1, indent: 64, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                SwitchListTile(
                  value: config.enableKillSwitch,
                  secondary: const Icon(Symbols.public_off_rounded),
                  title: const Text('Internet Kill Switch', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Block all internet traffic so no data can be downloaded or leaked.'),
                  onChanged: isActive
                      ? null
                      : (val) => _updateConfig(config.copyWith(enableKillSwitch: val)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Exit PIN Protection
          const SectionHeader(
            'Exit PIN Protection',
            subtitle: 'Prevent the borrower from turning off Public Mode prematurely.',
          ),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: Icon(
                config.pin != null ? Symbols.lock_rounded : Symbols.lock_reset_rounded,
                color: config.pin != null ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(
                config.pin != null ? 'Exit PIN Active' : 'Exit PIN Required',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                config.pin != null
                    ? (config.recoveryAnswer != null && config.recoveryAnswer!.isNotEmpty
                        ? '4-digit PIN with secret recovery question configured.'
                        : '4-digit PIN required to exit. Protected by device lock recovery.')
                    : 'A 4-digit PIN must be set to enable Public Mode.',
              ),
              trailing: isActive
                  ? const Text(
                      'Locked',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    )
                  : TextButton(
                      onPressed: () => _setOrChangePin(context, state),
                      child: Text(config.pin != null ? 'Change' : 'Set PIN'),
                    ),
              onTap: isActive ? null : () => _setOrChangePin(context, state),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _BlockedAppsPreview extends StatelessWidget {
  const _BlockedAppsPreview({
    required this.blockedPackages,
    required this.launchableApps,
    this.onManageTap,
  });

  final List<String> blockedPackages;
  final List<({String package, String label, dynamic icon})> launchableApps;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final appMap = {for (final a in launchableApps) a.package: a};

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pkg in blockedPackages) ...[
                  Chip(
                    avatar: appMap[pkg] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              appMap[pkg]!.icon,
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                   const Icon(Symbols.apps_rounded, size: 16),
                            ),
                          )
                        : const Icon(Symbols.apps_rounded, size: 16),
                    label: Text(appMap[pkg]?.label ?? pkg.split('.').last),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (onManageTap != null)
              InkWell(
                onTap: onManageTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.edit_rounded, size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Manage blocked apps',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.lock_rounded, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'App list is locked while Public Mode is active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionWarningCard extends StatelessWidget {
  const _PermissionWarningCard({
    required this.hasUsage,
    required this.hasOverlay,
    required this.hasDnd,
    this.isXiaomi = false,
    this.hasMiuiPopup = true,
    this.isIgnoringBattery = true,
    required this.onRefresh,
  });

  final bool hasUsage;
  final bool hasOverlay;
  final bool hasDnd;
  final bool isXiaomi;
  final bool hasMiuiPopup;
  final bool isIgnoringBattery;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final channel = context.read<QsChannel>();

    return Card(
      elevation: 0,
      color: const Color(0xFFFEF3C7).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Symbols.warning_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text(
                  'Permissions Required for App Blocking',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'To intercept restricted apps and display the block screen reliably across all phone models, the following permissions are required:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (!hasUsage)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.schedule_rounded),
                title: const Text('Usage Access', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Allows detecting when private apps open.'),
                trailing: TextButton(
                  onPressed: () async {
                    await channel.openUsageAccessSettings();
                    onRefresh();
                  },
                  child: const Text('Grant'),
                ),
              ),
            if (!hasOverlay)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.layers_rounded),
                title: const Text('Display Over Other Apps', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Allows showing the app block screen.'),
                trailing: TextButton(
                  onPressed: () async {
                    await channel.openOverlayPermissionSettings();
                    onRefresh();
                  },
                  child: const Text('Grant'),
                ),
              ),
            if (isXiaomi && !hasMiuiPopup)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.security_rounded, color: Color(0xFFF59E0B)),
                title: const Text('Display pop-up windows in background', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Required on Xiaomi, Redmi & POCO (MIUI / HyperOS) to intercept blocked apps.'),
                trailing: TextButton(
                  onPressed: () async {
                    await channel.openMiuiPermissions();
                    onRefresh();
                  },
                  child: const Text('Grant'),
                ),
              ),
            if (!isIgnoringBattery)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.battery_alert_rounded),
                title: const Text('Battery Optimization (Unrestricted)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Prevents aggressive OEM battery managers from killing the lock monitor.'),
                trailing: TextButton(
                  onPressed: () async {
                    await channel.requestIgnoreBatteryOptimizations();
                    onRefresh();
                  },
                  child: const Text('Exempt'),
                ),
              ),
            if (isXiaomi)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.autorenew_rounded),
                title: const Text('Autostart (Recommended for Xiaomi / POCO)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ensures Public Mode continues working while the phone is locked or idle.'),
                trailing: TextButton(
                  onPressed: () async {
                    await channel.openAutostartSettings();
                    onRefresh();
                  },
                  child: const Text('Check'),
                ),
              ),
            if (!hasDnd)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.notifications_off_rounded),
                title: const Text('Do Not Disturb Access (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Allows silencing notifications while handed over.'),
                trailing: TextButton(
                  onPressed: () async {
                    await channel.openDndPermissionSettings();
                    onRefresh();
                  },
                  child: const Text('Grant'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppPickerSheet extends StatefulWidget {
  const _AppPickerSheet({
    required this.initialBlocked,
    required this.apps,
    required this.onSaved,
  });

  final List<String> initialBlocked;
  final List<({String package, String label, dynamic icon})> apps;
  final ValueChanged<List<String>> onSaved;

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  late final Set<String> _selected = Set.from(widget.initialBlocked);
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final filtered = widget.apps.where((a) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return a.label.toLowerCase().contains(q) || a.package.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Select Private Apps',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${_selected.length} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Symbols.search_rounded),
                  hintText: 'Search installed apps...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (val) => setState(() => _search = val),
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  final isChecked = _selected.contains(app.package);

                  return CheckboxListTile(
                    value: isChecked,
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        app.icon,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Symbols.apps_rounded, size: 32),
                      ),
                    ),
                    title: Text(app.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      app.package,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(app.package);
                        } else {
                          _selected.remove(app.package);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    widget.onSaved(_selected.toList());
                    Navigator.of(context).pop();
                  },
                  child: Text('Done (${_selected.length} Apps)'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
