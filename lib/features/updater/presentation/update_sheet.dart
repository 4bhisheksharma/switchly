import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../cubit/update_cubit.dart';
import '../cubit/update_state.dart';
import '../models/update_info.dart';

/// Opens the update details bottom sheet.
Future<void> showUpdateSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<UpdateCubit>(),
      child: const UpdateSheet(),
    ),
  );
}

class UpdateSheet extends StatelessWidget {
  const UpdateSheet({super.key});

  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<UpdateCubit>().state;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header with icon and version badges
          _buildHeader(context, state),
          const SizedBox(height: 16),

          // Content body based on state
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildBody(context, state),
            ),
          ),
          const SizedBox(height: 16),

          // Action button
          _buildActionButton(context, state),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UpdateState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String title = 'Software Update';
    String subtitle = 'Keep Switchly fast and reliable';

    if (state is UpdateAvailable) {
      title = state.updateInfo.releaseTitle;
      subtitle = 'New version ready to install';
    } else if (state is UpdateDownloading) {
      title = 'Downloading Update';
      subtitle = state.formattedProgress;
    } else if (state is UpdateDownloaded) {
      title = 'Ready to Install';
      subtitle = 'Update has been downloaded';
    } else if (state is UpdateUpToDate) {
      title = 'You are on the latest version';
      subtitle = 'v${state.currentVersion} • Up to date';
    } else if (state is UpdateChecking) {
      title = 'Checking for updates...';
      subtitle = 'Connecting to GitHub Releases';
    } else if (state is UpdateError) {
      title = 'Update Check Failed';
      subtitle = 'Could not retrieve latest release';
    }

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Symbols.system_update_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, UpdateState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (state is UpdateChecking) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Checking GitHub releases...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is UpdateError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.error_outline_rounded, color: scheme.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is UpdateUpToDate) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(
              Symbols.check_circle_rounded,
              color: _green,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Switchly v${state.currentVersion} is the latest version.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your app is running the newest features and improvements.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final AppUpdateInfo? info = switch (state) {
      UpdateAvailable(:final updateInfo) => updateInfo,
      UpdateDownloading(:final updateInfo) => updateInfo,
      UpdateDownloaded(:final updateInfo) => updateInfo,
      _ => null,
    };

    if (info == null) return const SizedBox.shrink();

    final canInstall = switch (state) {
      UpdateAvailable(:final canInstall) => canInstall,
      UpdateDownloaded(:final canInstall) => canInstall,
      _ => true,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version Comparison Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                'Current: v${state.currentVersion}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Symbols.arrow_forward_rounded, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  info.tagName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (info.formattedSize.isNotEmpty)
                Text(
                  info.formattedSize,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Data Safety Guarantee Badge (Directly addresses user's concern)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _green.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Symbols.security_rounded, color: _green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'In-place update: All saved QR images, Quick Texts, and ADB permissions will remain intact.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Permission notice if Android blocks unknown app installs
        if (!canInstall) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Symbols.info_rounded, color: _amber, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Installation Permission Required',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _amber,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Android requires you to allow "Install unknown apps" for Switchly so it can update seamlessly.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => context.read<UpdateCubit>().openInstallPermissionSettings(),
                    child: const Text('Allow Permission'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Changelog / Release Notes
        Text(
          "What's New",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            info.changelog,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, UpdateState state) {
    final scheme = Theme.of(context).colorScheme;

    if (state is UpdateChecking) {
      return const SizedBox.shrink();
    }

    if (state is UpdateDownloading) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              minHeight: 8,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.formattedProgress,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (state is UpdateDownloaded) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Symbols.install_mobile_rounded, size: 20),
        label: const Text('Install Update Now', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.read<UpdateCubit>().installApk(state.apkPath);
        },
      );
    }

    if (state is UpdateAvailable) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Symbols.download_rounded, size: 20),
        label: const Text('Download & Update', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.read<UpdateCubit>().downloadAndInstall(state.updateInfo);
        },
      );
    }

    // Up to date or Error: Check again button
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Symbols.refresh_rounded, size: 20),
      label: const Text('Check for Updates Again'),
      onPressed: () {
        HapticFeedback.lightImpact();
        context.read<UpdateCubit>().checkForUpdate();
      },
    );
  }
}
