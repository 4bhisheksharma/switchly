import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/reminder_models.dart';

part 'reminders_event.dart';
part 'reminders_state.dart';

class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  RemindersBloc(this._repository) : super(const RemindersState()) {
    on<RemindersStarted>(_onStarted);
    on<RemindersRefreshed>(_onRefreshed);
    on<RemindersPermissionsChecked>(_onPermissionsChecked);
    on<ReminderSaved>(_onSaved);
    on<ReminderToggled>(_onToggled);
    on<ReminderCompletedToggled>(_onCompletedToggled);
    on<ReminderDeleted>(_onDeleted);
    on<ReminderRestored>(_onRestored);
    on<RemindersPastCleared>(_onPastCleared);

    _nativeSub = _repository.onNativeChanged.listen((_) {
      add(const RemindersRefreshed());
    });
  }

  final RemindersRepository _repository;
  late final StreamSubscription<void> _nativeSub;

  @override
  Future<void> close() {
    _nativeSub.cancel();
    return super.close();
  }

  Future<void> _onStarted(RemindersStarted event, Emitter<RemindersState> emit) async {
    final reminders = await _repository.load();
    final permissions = await _repository.getPermissions();
    emit(RemindersState(loaded: true, reminders: reminders, permissions: permissions));
    await _repository.syncReminders();
  }

  Future<void> _onRefreshed(RemindersRefreshed event, Emitter<RemindersState> emit) async {
    final reminders = await _repository.load();
    final permissions = await _repository.getPermissions();
    emit(state.copyWith(loaded: true, reminders: reminders, permissions: permissions));
  }

  Future<void> _onPermissionsChecked(
    RemindersPermissionsChecked event,
    Emitter<RemindersState> emit,
  ) async {
    final permissions = await _repository.getPermissions();
    emit(state.copyWith(permissions: permissions));
  }

  Future<void> _onSaved(ReminderSaved event, Emitter<RemindersState> emit) async {
    final list = [...state.reminders];
    final index = list.indexWhere((r) => r.id == event.reminder.id);
    if (index == -1) {
      list.add(event.reminder);
    } else {
      list[index] = event.reminder;
    }
    await _save(emit, list);
  }

  Future<void> _onToggled(ReminderToggled event, Emitter<RemindersState> emit) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = state.reminders.map((r) {
      if (r.id != event.id) return r;
      if (!event.enabled) {
        return r.copyWith(enabled: false);
      }
      var nextScheduled = r.scheduledAtMillis;
      if (nextScheduled <= now && r.repeat != ReminderRepeat.none) {
        nextScheduled = Reminder.nextOccurrenceAfter(r.scheduledAtMillis, r.repeat, now) ?? nextScheduled;
      }
      return r.copyWith(
        enabled: true,
        completed: false,
        scheduledAtMillis: nextScheduled,
        clearFiredAt: true,
        clearCompletedAt: true,
      );
    }).toList();
    await _save(emit, list);
  }

  Future<void> _onCompletedToggled(
    ReminderCompletedToggled event,
    Emitter<RemindersState> emit,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = state.reminders.map((r) {
      if (r.id != event.id) return r;
      if (event.completed) {
        return r.copyWith(
          completed: true,
          enabled: false,
          completedAtMillis: now,
        );
      }
      var nextScheduled = r.scheduledAtMillis;
      if (nextScheduled <= now && r.repeat != ReminderRepeat.none) {
        nextScheduled = Reminder.nextOccurrenceAfter(r.scheduledAtMillis, r.repeat, now) ?? nextScheduled;
      }
      return r.copyWith(
        completed: false,
        enabled: nextScheduled > now,
        scheduledAtMillis: nextScheduled,
        clearCompletedAt: true,
        clearFiredAt: true,
      );
    }).toList();
    await _save(emit, list);
  }

  Future<void> _onDeleted(ReminderDeleted event, Emitter<RemindersState> emit) async {
    await _save(emit, state.reminders.where((r) => r.id != event.id).toList());
  }

  Future<void> _onRestored(ReminderRestored event, Emitter<RemindersState> emit) async {
    final list = [...state.reminders];
    list.insert(event.index.clamp(0, list.length), event.reminder);
    await _save(emit, list);
  }

  Future<void> _onPastCleared(RemindersPastCleared event, Emitter<RemindersState> emit) async {
    await _save(emit, state.reminders.where((r) => r.isUpcoming).toList());
  }

  Future<void> _save(Emitter<RemindersState> emit, List<Reminder> reminders) async {
    emit(state.copyWith(loaded: true, reminders: reminders));
    await _repository.save(reminders);
  }
}
