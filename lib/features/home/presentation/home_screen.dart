import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
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
import '../../profiles/bloc/profiles_bloc.dart';
import '../../quick_texts/bloc/quick_texts_bloc.dart';
import '../../setup/bloc/setup_bloc.dart';
import '../../setup/data/setup_repository.dart';
import '../../setup/presentation/add_tiles.dart';
import '../../setup/presentation/permission_sheet.dart';

/// Overview of every tile with its live status.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setup = context.watch<SetupBloc>().state;
    final needsSetup = setup.status == SetupStatus.ready && !setup.hasPermission;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Title sits on the same row as the help icon instead of below it.
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            title: Text(
              'Switchly',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            actions: [
              IconButton(
                tooltip: 'How to add tiles',
                icon: const Icon(Symbols.help_rounded),
                onPressed: () => showAddTilesHelp(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "One-tap Quick Settings toggles Android doesn't give you.",
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: needsSetup
                      ? const Padding(padding: EdgeInsets.only(top: 20), child: _SetupBanner())
                      : const SizedBox(width: double.infinity),
                ),
                const SectionHeader('Network'),
                const _PrivateDnsCard(),
                const SizedBox(height: 10),
                const _KillSwitchCard(),
                const SizedBox(height: 10),
                const _WirelessDebuggingCard(),
                const SectionHeader('Display'),
                const _GrayscaleCard(),
                const SizedBox(height: 10),
                const _AnimationCard(),
                const SectionHeader('Everyday'),
                const _BsDateCard(),
                const SizedBox(height: 10),
                _TileCard(
                  tile: paymentQrTile,
                  status: _countLabel(context.select((PaymentQrBloc b) => b.state.qrs.length), 'QR code'),
                  active: false,
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.paymentQr),
                  trailing: Icon(Symbols.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                _TileCard(
                  tile: quickTextsTile,
                  status: _countLabel(context.select((QuickTextsBloc b) => b.state.texts.length), 'text'),
                  active: false,
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.quickTexts),
                  // Not an on/off tile, so no status pill.
                  trailing: Icon(Symbols.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                const _ProfilesCard(),
                const SizedBox(height: 32),
                const _PrivacyFooter(),
              ],
            ),
          ),
        ],
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: AppTheme.brandGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.key_rounded, color: Colors.white, fill: 1),
              const SizedBox(width: 10),
              Text('Finish setup', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grant a one-time permission so your tiles can change system settings.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
            onPressed: () => showPermissionSheet(context),
            child: const Text('Set up now'),
          ),
        ],
      ),
    );
  }
}

/// One row per tile: icon, live status, and either a chevron or an inline [trailing] control.
class _TileCard extends StatelessWidget {
  const _TileCard({
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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              TileIcon(tile.icon, active: active, size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        status,
                        key: ValueKey(status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          fontWeight: active ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...trailing != null
                  ? [trailing!]
                  : [
                      StatusPill(active ? 'On' : 'Off', highlighted: active),
                      const SizedBox(width: 4),
                      Icon(Symbols.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivateDnsCard extends StatelessWidget {
  const _PrivateDnsCard();

  @override
  Widget build(BuildContext context) {
    final dns = context.watch<DnsBloc>().state;
    final active = dns.live?.isEncrypted ?? false;
    return _TileCard(
      tile: privateDnsTile,
      status: active ? dns.liveLabel : 'Encrypted DNS is ${dns.liveLabel.toLowerCase()}',
      active: active,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.dns),
    );
  }
}

/// Grayscale has no settings, so it toggles right here.
class _GrayscaleCard extends StatelessWidget {
  const _GrayscaleCard();

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

    return _TileCard(
      tile: grayscaleTile,
      status: on ? 'Screen is in grayscale' : 'Full colour',
      active: on,
      onTap: toggle,
      trailing: Switch(value: on, onChanged: (_) => toggle()),
    );
  }
}

class _AnimationCard extends StatelessWidget {
  const _AnimationCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DisplayBloc>().state;
    final speed = state.speed;
    return _TileCard(
      tile: animationSpeedTile,
      status: switch (state.scales) {
        null => '—',
        _ when speed == null => 'Custom speeds',
        _ when sameSpeed(speed, 0) => 'Animations off',
        _ => '${speedLabel(speed)} · ${speedDescription(speed)}',
      },
      active: state.animationModified,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.animation),
    );
  }
}

String _countLabel(int count, String noun) => switch (count) {
      0 => 'No ${noun}s saved',
      1 => '1 $noun saved',
      _ => '$count ${noun}s saved',
    };

class _KillSwitchCard extends StatelessWidget {
  const _KillSwitchCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NetworkBloc>().state;
    final on = state.killSwitchOn;
    final allowed = state.allowedApps.length;
    return _TileCard(
      tile: killSwitchTile,
      status: on ? (allowed == 0 ? 'Internet blocked' : 'Blocked · $allowed allowed') : 'Internet on',
      active: on,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.killSwitch),
    );
  }
}

/// Toggles inline; while on, shows the address to connect to with a copy button.
class _WirelessDebuggingCard extends StatelessWidget {
  const _WirelessDebuggingCard();

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

    return _TileCard(
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
            IconButton(tooltip: 'Copy adb connect', icon: const Icon(Symbols.content_copy_rounded), onPressed: copyAddress),
          if (status?.wirelessSupported ?? false)
            status!.devOptions
                ? Switch(value: on, onChanged: (_) => toggle())
                : Icon(Symbols.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _BsDateCard extends StatelessWidget {
  const _BsDateCard();

  @override
  Widget build(BuildContext context) {
    final nepali = context.watch<BsScriptCubit>().state;
    final today = DateTime.now().toNepaliDateTime();
    return _TileCard(
      tile: bsDateTile,
      status: '${BsFormat.weekday(today, nepali)}, ${BsFormat.date(today, nepali)}',
      active: true,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.calendar),
      trailing: Icon(Symbols.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _ProfilesCard extends StatelessWidget {
  const _ProfilesCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfilesBloc>().state;
    final active = state.active;
    return _TileCard(
      tile: profilesTile,
      status: active != null ? '${active.name} is active' : _countLabel(state.profiles.length, 'profile'),
      active: active != null,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.profiles),
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Symbols.verified_user_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text('Fully offline · No tracking', style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
