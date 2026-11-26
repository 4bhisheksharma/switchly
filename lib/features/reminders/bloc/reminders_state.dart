part of 'reminders_bloc.dart';

class RemindersState extends Equatable {
  const RemindersState({
    this.loaded = false,
    this.reminders = const [],
    this.permissions = const ReminderPermissions(),
  });

  final bool loaded;
  final List<Reminder> reminders;
  final ReminderPermissions permissions;

  List<Reminder> get upcoming =>
      reminders.where((r) => r.isUpcoming).toList()
        ..sort((a, b) => a.scheduledAtMillis.compareTo(b.scheduledAtMillis));

  List<Reminder> get pastAndCompleted =>
      reminders.where((r) => !r.isUpcoming).toList()
        ..sort(
          (a, b) => (b.completedAtMillis ?? b.firedAtMillis ?? b.scheduledAtMillis)
              .compareTo(a.completedAtMillis ?? a.firedAtMillis ?? a.scheduledAtMillis),
        );

  Reminder? get nextUpcoming => upcoming.firstOrNull;

  int get upcomingCount => upcoming.length;

  RemindersState copyWith({
    bool? loaded,
    List<Reminder>? reminders,
    ReminderPermissions? permissions,
  }) {
    return RemindersState(
      loaded: loaded ?? this.loaded,
      reminders: reminders ?? this.reminders,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [loaded, reminders, permissions];
}
