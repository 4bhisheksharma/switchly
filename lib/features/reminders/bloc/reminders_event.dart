part of 'reminders_bloc.dart';

sealed class RemindersEvent extends Equatable {
  const RemindersEvent();

  @override
  List<Object?> get props => [];
}

final class RemindersStarted extends RemindersEvent {
  const RemindersStarted();
}

final class RemindersRefreshed extends RemindersEvent {
  const RemindersRefreshed();
}

final class RemindersPermissionsChecked extends RemindersEvent {
  const RemindersPermissionsChecked();
}

final class ReminderSaved extends RemindersEvent {
  const ReminderSaved(this.reminder);

  final Reminder reminder;

  @override
  List<Object?> get props => [reminder];
}

final class ReminderToggled extends RemindersEvent {
  const ReminderToggled(this.id, this.enabled);

  final String id;
  final bool enabled;

  @override
  List<Object?> get props => [id, enabled];
}

final class ReminderCompletedToggled extends RemindersEvent {
  const ReminderCompletedToggled(this.id, this.completed);

  final String id;
  final bool completed;

  @override
  List<Object?> get props => [id, completed];
}

final class ReminderDeleted extends RemindersEvent {
  const ReminderDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ReminderRestored extends RemindersEvent {
  const ReminderRestored(this.reminder, this.index);

  final Reminder reminder;
  final int index;

  @override
  List<Object?> get props => [reminder, index];
}

final class RemindersPastCleared extends RemindersEvent {
  const RemindersPastCleared();
}
