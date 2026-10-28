import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/tile_icon.dart';
import '../cubit/update_cubit.dart';
import '../cubit/update_state.dart';
import 'update_sheet.dart';

/// Preference tile displayed in the settings/preferences section.
class UpdateCheckTile extends StatelessWidget {
  const UpdateCheckTile({super.key});

  static const Color _green = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<UpdateCubit>().state;

    String subtitle = 'Tap to check for latest release';
    Widget? trailing;

    if (state is UpdateChecking) {
      subtitle = 'Checking GitHub releases...';
      trailing = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: scheme.primary,
        ),
      );
    } else if (state is UpdateAvailable) {
      subtitle = 'New version ${state.updateInfo.tagName} available';
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 6, height: 6),
            ),
            SizedBox(width: 5),
            Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (state is UpdateDownloading) {
      subtitle = 'Downloading: ${state.formattedProgress}';
      trailing = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          value: state.progress > 0 ? state.progress : null,
          strokeWidth: 2,
          color: scheme.primary,
        ),
      );
    } else if (state is UpdateDownloaded) {
      subtitle = 'Downloaded • Tap to install';
      trailing = const Icon(
        Symbols.install_mobile_rounded,
        size: 20,
        color: _green,
      );
    } else if (state is UpdateUpToDate) {
      subtitle = 'v${state.currentVersion} • App is up to date';
      trailing = const Icon(
        Symbols.check_circle_rounded,
        size: 18,
        color: _green,
      );
    } else if (state is UpdateError) {
      subtitle = 'Check failed • Tap to retry';
      trailing = Icon(
        Symbols.error_outline_rounded,
        size: 18,
        color: scheme.error,
      );
    } else if (state.currentVersion.isNotEmpty) {
      subtitle = 'v${state.currentVersion} • Tap to check for updates';
      trailing = const Icon(Symbols.chevron_right_rounded, size: 20);
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (state is UpdateAvailable ||
            state is UpdateDownloading ||
            state is UpdateDownloaded) {
          showUpdateSheet(context);
        } else {
          context.read<UpdateCubit>().checkForUpdate();
          showUpdateSheet(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            TileIcon(
              Symbols.system_update_rounded,
              active: state is UpdateAvailable,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check for Updates',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: state is UpdateAvailable
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: state is UpdateAvailable
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact banner displayed on the home screen when a new update is ready.
class UpdateNotificationBanner extends StatelessWidget {
  const UpdateNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UpdateCubit>().state;
    if (state is! UpdateAvailable && state is! UpdateDownloaded) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (isDownloaded, tagName) = switch (state) {
      UpdateDownloaded(:final updateInfo) => (true, updateInfo.tagName),
      UpdateAvailable(:final updateInfo) => (false, updateInfo.tagName),
      _ => (false, ''),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showUpdateSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDownloaded
                        ? Symbols.install_mobile_rounded
                        : Symbols.download_rounded,
                    color: scheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDownloaded
                            ? 'Switchly $tagName downloaded'
                            : 'Update $tagName available',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDownloaded
                            ? 'Tap to install without losing any data'
                            : 'Tap to view changelog and update',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDownloaded ? 'Install' : 'Update',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
