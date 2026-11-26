import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/select_chip.dart';
import '../data/reminder_models.dart';

/// Opens the add/edit reminder bottom sheet. Returns the saved [Reminder], or null if dismissed.
Future<Reminder?> showReminderEditor(
  BuildContext context, {
  Reminder? editing,
  bool reschedule = false,
}) {
  return showModalBottomSheet<Reminder>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReminderEditorSheet(editing: editing, reschedule: reschedule),
  );
}

class _ReminderEditorSheet extends StatefulWidget {
  const _ReminderEditorSheet({this.editing, this.reschedule = false});

  final Reminder? editing;
  final bool reschedule;

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.editing?.title);
  late final _note = TextEditingController(text: widget.editing?.note);

  late DateTime _scheduledAt;
  late ReminderRepeat _repeat;
  bool _timeInPastError = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultTime = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(const Duration(minutes: 30));
    final editing = widget.editing;
    if (editing == null) {
      _scheduledAt = defaultTime;
      _repeat = ReminderRepeat.none;
    } else if (widget.reschedule && !editing.scheduledAt.isAfter(now)) {
      _scheduledAt = defaultTime;
      _repeat = editing.repeat;
    } else {
      _scheduledAt = editing.scheduledAt;
      _repeat = editing.repeat;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _scheduledAt.isBefore(today) ? today : _scheduledAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
      _timeInPastError = false;
    });
  }

  Future<void> _pickTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
      _timeInPastError = false;
    });
  }

  void _applyPreset(DateTime target) {
    HapticFeedback.selectionClick();
    setState(() {
      _scheduledAt = target;
      _timeInPastError = false;
    });
  }

  void _save() {
    final formValid = _formKey.currentState!.validate();
    final inFuture = _scheduledAt.isAfter(DateTime.now());
    if (!inFuture) {
      setState(() => _timeInPastError = true);
    }
    if (!formValid || !inFuture) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final editing = widget.editing;
    Navigator.of(context).pop(
      Reminder(
        id: editing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        note: _note.text.trim(),
        scheduledAtMillis: _scheduledAt.millisecondsSinceEpoch,
        repeat: _repeat,
        enabled: true,
        completed: false,
        createdAtMillis: editing?.createdAtMillis ?? nowMs,
      ),
    );
  }

  List<({String label, DateTime target})> _buildPresets(DateTime now) {
    final baseMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final tonight = DateTime(now.year, now.month, now.day, 20, 0);
    final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 9, 0);
    final tomorrowEvening = DateTime(now.year, now.month, now.day + 1, 18, 0);

    return [
      (label: '+15 min', target: baseMinute.add(const Duration(minutes: 15))),
      (label: '+1 hour', target: baseMinute.add(const Duration(hours: 1))),
      if (tonight.isAfter(now.add(const Duration(minutes: 10))))
        (label: 'Tonight 8 PM', target: tonight),
      (label: 'Tomorrow 9 AM', target: tomorrowMorning),
      (label: 'Tomorrow 6 PM', target: tomorrowEvening),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final presets = _buildPresets(now);

    final dateText = localizations.formatMediumDate(_scheduledAt);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(_scheduledAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final isFuture = _scheduledAt.isAfter(now);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.editing == null
                    ? 'New reminder'
                    : (widget.reschedule ? 'Reschedule reminder' : 'Edit reminder'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                autofocus: widget.editing == null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Reminder title',
                  hintText: 'e.g. Take medicine, Pay electricity bill',
                  prefixIcon: Icon(Symbols.notifications_active_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a reminder title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Extra details shown in the notification',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick presets',
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in presets)
                    ActionChip(
                      label: Text(preset.label),
                      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
                      backgroundColor: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onPressed: () => _applyPreset(preset.target),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Date & time',
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Symbols.calendar_today_rounded,
                      label: 'Date',
                      value: dateText,
                      error: _timeInPastError && !isFuture,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Symbols.access_time_rounded,
                      label: 'Time',
                      value: timeText,
                      error: _timeInPastError && !isFuture,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_timeInPastError && !isFuture)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Pick a date and time in the future.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (isFuture)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(Symbols.schedule_rounded, size: 15, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        _relativeHint(_scheduledAt, now),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Repeat',
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in ReminderRepeat.values)
                    SelectChip(
                      label: r.label,
                      selected: _repeat == r,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _repeat = r);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Symbols.alarm_on_rounded, size: 20),
                  label: Text(widget.editing == null ? 'Schedule reminder' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.error,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: error ? scheme.error : scheme.outlineVariant.withValues(alpha: 0.7),
          width: error ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: error ? scheme.error : scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeHint(DateTime target, DateTime now) {
  final diff = target.difference(now);
  if (diff.inSeconds < 60) return 'Triggers in less than a minute';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'Triggers in $m ${m == 1 ? 'minute' : 'minutes'}';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m == 0 ? 'Triggers in $h ${h == 1 ? 'hour' : 'hours'}' : 'Triggers in ${h}h ${m}m';
  }
  final d = diff.inDays;
  return 'Triggers in $d ${d == 1 ? 'day' : 'days'}';
}
