import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/tiles/tile_catalog.dart';
import '../../../core/widgets/hero_status_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tile_icon.dart';
import '../../setup/presentation/add_tiles.dart';
import '../bloc/reminders_bloc.dart';
import '../data/reminder_models.dart';
import 'reminder_editor_sheet.dart';

/// Manage offline scheduled reminders and notification/exact-alarm permissions.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    context.read<RemindersBloc>().add(const RemindersRefreshed());
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _addReminder(BuildContext context) async {
    final bloc = context.read<RemindersBloc>();
    final repo = context.read<RemindersRepository>();
    final reminder = await showReminderEditor(context);
    if (reminder == null || !mounted) return;
    bloc.add(ReminderSaved(reminder));
    await _ensureNotificationPermissionIfNeeded(repo, bloc);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Scheduled for ${formatReminderDateTime(context, reminder.scheduledAt)}'),
        ),
      );
  }

  Future<void> _editReminder(
    BuildContext context,
    Reminder reminder, {
    bool reschedule = false,
  }) async {
    final bloc = context.read<RemindersBloc>();
    final repo = context.read<RemindersRepository>();
    final updated = await showReminderEditor(context, editing: reminder, reschedule: reschedule);
    if (updated == null || !mounted) return;
    bloc.add(ReminderSaved(updated));
    await _ensureNotificationPermissionIfNeeded(repo, bloc);
  }

  Future<void> _ensureNotificationPermissionIfNeeded(
    RemindersRepository repo,
    RemindersBloc bloc,
  ) async {
    if (!bloc.state.permissions.notificationsAllowed) {
      await repo.requestNotificationPermission();
      bloc.add(const RemindersPermissionsChecked());
    }
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    HapticFeedback.selectionClick();
    final repo = context.read<RemindersRepository>();
    final bloc = context.read<RemindersBloc>();
    if (!bloc.state.permissions.notificationsAllowed) {
      final granted = await repo.requestNotificationPermission();
      bloc.add(const RemindersPermissionsChecked());
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Enable notifications to receive reminders.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => repo.openNotificationSettings(),
              ),
            ),
          );
        return;
      }
    }
    final sent = await repo.sendTestNotification();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Test reminder notification sent!'
                : 'Could not send notification. Check system notification settings.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RemindersBloc>().state;
    final upcoming = state.upcoming;
    final past = state.pastAndCompleted;
    final next = state.nextUpcoming;
    final perms = state.permissions;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context),
        icon: const Icon(Symbols.add_alert_rounded),
        label: const Text('New reminder'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Reminders'),
            actions: [
              IconButton(
                tooltip: 'Send test notification',
                icon: const Icon(Symbols.mark_chat_unread_rounded, size: 22),
                onPressed: () => _sendTestNotification(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                HeroStatusCard(
                  icon: upcoming.isNotEmpty
                      ? Symbols.alarm_on_rounded
                      : Symbols.notifications_active_rounded,
                  label: upcoming.isNotEmpty ? 'NEXT REMINDER' : 'REMINDERS',
                  value: next != null ? next.title : 'No upcoming reminders',
                  detail: next != null
                      ? '${formatReminderDateTime(context, next.scheduledAt)} · ${upcoming.length} scheduled'
                      : 'Pick any date and time to receive an offline push notification.',
                  active: upcoming.isNotEmpty,
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        style: upcoming.isNotEmpty
                            ? FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF4F46E5),
                              )
                            : null,
                        onPressed: () => _addReminder(context),
                        icon: const Icon(Symbols.add_alert_rounded, size: 20),
                        label: const Text('New reminder'),
                      ),
                      if (canRequestAddTile(context))
                        AddTileButton(remindersTile, onGradient: upcoming.isNotEmpty),
                    ],
                  ),
                ),
                if (perms.needsAttention) ...[
                  const SizedBox(height: 16),
                  _PermissionBanner(permissions: perms),
                ],
              ],
            ),
          ),
          if (state.loaded && state.reminders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onAdd: () => _addReminder(context)),
            )
          else ...[
            if (upcoming.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    'Upcoming',
                    subtitle: 'Scheduled on-device. Works offline and across reboots.',
                    trailing: StatusPill('${upcoming.length} active', highlighted: true),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: upcoming.length,
                  itemBuilder: (context, i) => _ReminderCard(
                    reminder: upcoming[i],
                    index: state.reminders.indexOf(upcoming[i]),
                    onEdit: () => _editReminder(context, upcoming[i]),
                    onReschedule: () => _editReminder(context, upcoming[i], reschedule: true),
                  ),
                ),
              ),
            ],
            if (past.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    'Past & completed',
                    trailing: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.read<RemindersBloc>().add(const RemindersPastCleared());
                      },
                      icon: const Icon(Symbols.delete_sweep_rounded, size: 18),
                      label: const Text('Clear'),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: past.length,
                  itemBuilder: (context, i) => _ReminderCard(
                    reminder: past[i],
                    index: state.reminders.indexOf(past[i]),
                    onEdit: () => _editReminder(context, past[i]),
                    onReschedule: () => _editReminder(context, past[i], reschedule: true),
                  ),
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverToBoxAdapter(
                child: _InfoNote(isIgnoringBattery: perms.isIgnoringBattery),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.permissions});

  final ReminderPermissions permissions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<RemindersRepository>();
    final bloc = context.read<RemindersBloc>();

    return Card(
      color: const Color(0xFFFEF3C7).withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Symbols.notification_important_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions needed for timely reminders',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!permissions.notificationsAllowed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.notifications_active_rounded),
                title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Required to display reminder alerts when due.'),
                trailing: TextButton(
                  onPressed: () async {
                    await repo.requestNotificationPermission();
                    bloc.add(const RemindersPermissionsChecked());
                  },
                  child: const Text('Allow'),
                ),
              ),
            if (!permissions.canScheduleExactAlarms)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.alarm_on_rounded),
                title: const Text('Exact alarms', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Lets reminders fire at the exact minute, even in Doze mode.'),
                trailing: TextButton(
                  onPressed: () async {
                    await repo.openExactAlarmSettings();
                    bloc.add(const RemindersPermissionsChecked());
                  },
                  child: const Text('Allow'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.index,
    required this.onEdit,
    required this.onReschedule,
  });

  final Reminder reminder;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bloc = context.read<RemindersBloc>();
    final now = DateTime.now();
    final isUpcoming = reminder.isUpcoming;
    final isPastDue = isUpcoming && !reminder.scheduledAt.isAfter(now);

    final statusPill = switch (reminder) {
      _ when reminder.completed => const StatusPill('Done'),
      _ when reminder.isPastTriggered => const StatusPill('Triggered'),
      _ when reminder.isPaused => const StatusPill('Paused'),
      _ when isPastDue => const StatusPill('Due now', highlighted: true),
      _ => null,
    };

    void handleSwitch(bool value) {
      HapticFeedback.selectionClick();
      if (value && reminder.repeat == ReminderRepeat.none && !reminder.scheduledAt.isAfter(now)) {
        onReschedule();
      } else {
        bloc.add(ReminderToggled(reminder.id, value));
      }
    }

    void handleDoneToggle() {
      HapticFeedback.selectionClick();
      if (reminder.completed &&
          reminder.repeat == ReminderRepeat.none &&
          !reminder.scheduledAt.isAfter(now)) {
        onReschedule();
      } else {
        bloc.add(ReminderCompletedToggled(reminder.id, !reminder.completed));
      }
    }

    void deleteWithUndo() {
      bloc.add(ReminderDeleted(reminder.id));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Deleted “${reminder.title}”'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => bloc.add(ReminderRestored(reminder, index < 0 ? 0 : index)),
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: isUpcoming ? onEdit : onReschedule,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: reminder.completed ? 'Mark as not done' : 'Mark as done',
                  icon: Icon(
                    reminder.completed
                        ? Symbols.check_circle_rounded
                        : Symbols.radio_button_unchecked_rounded,
                    fill: reminder.completed ? 1 : 0,
                    color: reminder.completed
                        ? colors.primary
                        : colors.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                  onPressed: handleDoneToggle,
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isUpcoming ? 1 : 0.65,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: reminder.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (reminder.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.note.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUpcoming
                                    ? colors.primary.withValues(alpha: 0.1)
                                    : colors.surfaceContainerHigh.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Symbols.event_rounded,
                                    size: 14,
                                    color: isUpcoming ? colors.primary : colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    formatReminderDateTime(context, reminder.scheduledAt),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isUpcoming ? colors.primary : colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (reminder.repeat != ReminderRepeat.none)
                              StatusPill(reminder.repeat.label, highlighted: isUpcoming),
                            ?statusPill,
                            if (isUpcoming && !isPastDue)
                              Text(
                                _shortCountdown(reminder.scheduledAt, now),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Options',
                          icon: Icon(
                            Symbols.more_vert_rounded,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                onEdit();
                              case 'reschedule':
                                onReschedule();
                              case 'done':
                                handleDoneToggle();
                              case 'delete':
                                deleteWithUndo();
                            }
                          },
                          itemBuilder: (ctx) {
                            final scheme = Theme.of(ctx).colorScheme;
                            return [
                              PopupMenuItem(
                                value: isUpcoming ? 'edit' : 'reschedule',
                                child: Row(
                                  children: [
                                    Icon(
                                      isUpcoming ? Symbols.edit_rounded : Symbols.event_repeat_rounded,
                                      size: 20,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isUpcoming ? 'Edit' : 'Reschedule',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'done',
                                child: Row(
                                  children: [
                                    Icon(Symbols.done_all_rounded, size: 20, color: scheme.primary),
                                    const SizedBox(width: 12),
                                    Text(
                                      reminder.completed ? 'Mark active' : 'Mark done',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Symbols.delete_rounded, size: 20, color: scheme.error),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: scheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                        const SizedBox(width: 4),
                        Switch(value: isUpcoming, onChanged: handleSwitch),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TileIcon(Symbols.notifications_active_rounded, size: 72),
          const SizedBox(height: 20),
          Text('No reminders yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Set any date and time to receive a local push notification right on your device. No internet or cloud account needed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Symbols.add_alert_rounded, size: 20),
            label: const Text('Create reminder'),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.isIgnoringBattery});

  final bool isIgnoringBattery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final repo = context.read<RemindersRepository>();
    final bloc = context.read<RemindersBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.info_rounded, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reminders are stored privately on your device and automatically reschedule after phone restarts.',
                style: theme.textTheme.bodySmall?.copyWith(color: color, height: 1.5),
              ),
            ),
          ],
        ),
        if (!isIgnoringBattery) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: TextButton.icon(
              onPressed: () async {
                await repo.requestIgnoreBatteryOptimizations();
                bloc.add(const RemindersPermissionsChecked());
              },
              icon: const Icon(Symbols.battery_saver_rounded, size: 18),
              label: const Text('Allow unrestricted battery for reliable alerts'),
            ),
          ),
        ],
      ],
    );
  }
}

String formatReminderDateTime(BuildContext context, DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final targetDay = DateTime(dt.year, dt.month, dt.day);
  final loc = MaterialLocalizations.of(context);
  final timeText = loc.formatTimeOfDay(
    TimeOfDay.fromDateTime(dt),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  if (targetDay == today) return 'Today · $timeText';
  if (targetDay == tomorrow) return 'Tomorrow · $timeText';
  return '${loc.formatShortDate(dt)} · $timeText';
}

String _shortCountdown(DateTime target, DateTime now) {
  final diff = target.difference(now);
  if (diff.inMinutes < 1) return 'in <1m';
  if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m == 0 ? 'in ${h}h' : 'in ${h}h ${m}m';
  }
  return 'in ${diff.inDays}d';
}
