import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/qs_channel.dart';
import '../../../core/storage/pref_keys.dart';

enum ReminderRepeat {
  none('none', 'Once'),
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly');

  const ReminderRepeat(this.key, this.label);

  final String key;
  final String label;

  static ReminderRepeat fromKey(String? key) =>
      values.firstWhere((r) => r.key == key, orElse: () => ReminderRepeat.none);
}

/// A scheduled local notification reminder. Mirrors `Reminder` in android/.../reminders/Reminders.kt.
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    this.note = '',
    required this.scheduledAtMillis,
    this.repeat = ReminderRepeat.none,
    this.enabled = true,
    this.completed = false,
    required this.createdAtMillis,
    this.firedAtMillis,
    this.completedAtMillis,
  });

  factory Reminder.fromJson(Map<String, Object?> json) => Reminder(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        note: json['note'] as String? ?? '',
        scheduledAtMillis: (json['scheduledAtMillis'] as num?)?.toInt() ?? 0,
        repeat: ReminderRepeat.fromKey(json['repeat'] as String?),
        enabled: json['enabled'] as bool? ?? true,
        completed: json['completed'] as bool? ?? false,
        createdAtMillis: (json['createdAtMillis'] as num?)?.toInt() ?? 0,
        firedAtMillis: (json['firedAtMillis'] as num?)?.toInt(),
        completedAtMillis: (json['completedAtMillis'] as num?)?.toInt(),
      );

  final String id;
  final String title;
  final String note;
  final int scheduledAtMillis;
  final ReminderRepeat repeat;
  final bool enabled;
  final bool completed;
  final int createdAtMillis;
  final int? firedAtMillis;
  final int? completedAtMillis;

  DateTime get scheduledAt => DateTime.fromMillisecondsSinceEpoch(scheduledAtMillis);

  bool get isUpcoming => enabled && !completed;
  bool get isPastTriggered => !enabled && !completed && firedAtMillis != null;
  bool get isPaused => !enabled && !completed && firedAtMillis == null;

  Reminder copyWith({
    String? id,
    String? title,
    String? note,
    int? scheduledAtMillis,
    ReminderRepeat? repeat,
    bool? enabled,
    bool? completed,
    int? createdAtMillis,
    int? firedAtMillis,
    bool clearFiredAt = false,
    int? completedAtMillis,
    bool clearCompletedAt = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      scheduledAtMillis: scheduledAtMillis ?? this.scheduledAtMillis,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
      completed: completed ?? this.completed,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      firedAtMillis: clearFiredAt ? null : (firedAtMillis ?? this.firedAtMillis),
      completedAtMillis: clearCompletedAt ? null : (completedAtMillis ?? this.completedAtMillis),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'scheduledAtMillis': scheduledAtMillis,
        'repeat': repeat.key,
        'enabled': enabled,
        'completed': completed,
        'createdAtMillis': createdAtMillis,
        'firedAtMillis': firedAtMillis,
        'completedAtMillis': completedAtMillis,
      };

  /// Computes the next local occurrence strictly after [nowMillis] for repeating reminders.
  static int? nextOccurrenceAfter(int baseMillis, ReminderRepeat repeat, int nowMillis) {
    if (repeat == ReminderRepeat.none) return null;
    final base = DateTime.fromMillisecondsSinceEpoch(baseMillis);
    if (repeat == ReminderRepeat.monthly) {
      var steps = 1;
      while (steps <= 1200) {
        final targetMonthStart = DateTime(base.year, base.month + steps, 1);
        final lastDayOfMonth = DateTime(targetMonthStart.year, targetMonthStart.month + 1, 0).day;
        final day = base.day.clamp(1, lastDayOfMonth);
        final candidate = DateTime(
          targetMonthStart.year,
          targetMonthStart.month,
          day,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
        );
        if (candidate.millisecondsSinceEpoch > nowMillis) {
          return candidate.millisecondsSinceEpoch;
        }
        steps++;
      }
      return null;
    }

    final dayStep = repeat == ReminderRepeat.weekly ? 7 : 1;
    var candidate = base;
    while (candidate.millisecondsSinceEpoch <= nowMillis) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + dayStep,
        candidate.hour,
        candidate.minute,
        candidate.second,
        candidate.millisecond,
      );
    }
    return candidate.millisecondsSinceEpoch;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        note,
        scheduledAtMillis,
        repeat,
        enabled,
        completed,
        createdAtMillis,
        firedAtMillis,
        completedAtMillis,
      ];
}

class ReminderPermissions extends Equatable {
  const ReminderPermissions({
    this.notificationsAllowed = true,
    this.canScheduleExactAlarms = true,
    this.isIgnoringBattery = true,
    this.sdkInt = 33,
  });

  final bool notificationsAllowed;
  final bool canScheduleExactAlarms;
  final bool isIgnoringBattery;
  final int sdkInt;

  bool get needsAttention => !notificationsAllowed || !canScheduleExactAlarms;

  @override
  List<Object?> get props => [
        notificationsAllowed,
        canScheduleExactAlarms,
        isIgnoringBattery,
        sdkInt,
      ];
}

class RemindersRepository {
  const RemindersRepository({this.channel});

  final QsChannel? channel;

  Stream<void> get onNativeChanged => channel?.onRemindersChanged ?? const Stream.empty();

  Future<List<Reminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(PrefKeys.reminders);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<Object?>;
      return [
        for (final item in decoded)
          if (item is Map<String, Object?>) Reminder.fromJson(item),
      ].where((r) => r.id.isNotEmpty && r.title.isNotEmpty).toList();
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.reminders, jsonEncode([for (final r in reminders) r.toJson()]));
    await syncReminders();
  }

  Future<void> syncReminders() async {
    try {
      await channel?.syncReminders();
    } on MissingPluginException {
      // Ignored in pure Flutter unit tests.
    } on PlatformException {
      // Best-effort sync.
    }
  }

  Future<ReminderPermissions> getPermissions() async {
    final ch = channel;
    if (ch == null) return const ReminderPermissions();
    try {
      final p = await ch.getReminderPermissions();
      return ReminderPermissions(
        notificationsAllowed: p.notificationsAllowed,
        canScheduleExactAlarms: p.canScheduleExactAlarms,
        isIgnoringBattery: p.isIgnoringBattery,
        sdkInt: p.sdkInt,
      );
    } on MissingPluginException {
      return const ReminderPermissions();
    } on PlatformException {
      return const ReminderPermissions();
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      return await channel?.requestNotificationPermission() ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> openNotificationSettings() async {
    try {
      return await channel?.openNotificationSettings() ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> openExactAlarmSettings() async {
    try {
      return await channel?.openExactAlarmSettings() ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      return await channel?.requestIgnoreBatteryOptimizations() ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      return await channel?.sendTestReminderNotification() ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
