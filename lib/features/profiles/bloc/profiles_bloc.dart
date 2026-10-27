import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/profile_models.dart';

part 'profiles_event.dart';
part 'profiles_state.dart';

/// Saved profiles and which one (if any) is applied.
class ProfilesBloc extends Bloc<ProfilesEvent, ProfilesState> {
  ProfilesBloc(this._repository) : super(const ProfilesState()) {
    on<ProfilesStarted>(_onStarted);
    on<ProfilesRefreshed>(_onRefreshed);
    on<ProfileSaved>(_onSaved);
    on<ProfileDeleted>(_onDeleted);
    on<ProfileApplied>(_onApplied);
    on<ProfileRestoreRequested>(_onRestoreRequested);
  }

  final ProfilesRepository _repository;

  Future<void> _onStarted(ProfilesStarted event, Emitter<ProfilesState> emit) async {
    emit(state.copyWith(loaded: true, profiles: await _repository.load()));
    await _refreshActive(emit);
  }

  Future<void> _onRefreshed(ProfilesRefreshed event, Emitter<ProfilesState> emit) => _refreshActive(emit);

  Future<void> _onSaved(ProfileSaved event, Emitter<ProfilesState> emit) async {
    final profiles = [...state.profiles];
    final index = profiles.indexWhere((p) => p.id == event.profile.id);
    if (index == -1) {
      profiles.add(event.profile);
    } else {
      profiles[index] = event.profile;
    }
    emit(state.copyWith(profiles: profiles));
    await _repository.save(profiles);
  }

  Future<void> _onDeleted(ProfileDeleted event, Emitter<ProfilesState> emit) async {
    final profiles = state.profiles.where((p) => p.id != event.id).toList();
    emit(state.copyWith(profiles: profiles));
    await _repository.save(profiles);
  }

  Future<void> _onApplied(ProfileApplied event, Emitter<ProfilesState> emit) async {
    emit(state.copyWith(busy: true));
    final ok = await _repository.apply(event.id);
    emit(state.copyWith(busy: false, failures: ok ? null : state.failures + 1));
    await _refreshActive(emit);
  }

  Future<void> _onRestoreRequested(ProfileRestoreRequested event, Emitter<ProfilesState> emit) async {
    emit(state.copyWith(busy: true));
    final ok = await _repository.restore();
    emit(state.copyWith(busy: false, failures: ok ? null : state.failures + 1));
    await _refreshActive(emit);
  }

  Future<void> _refreshActive(Emitter<ProfilesState> emit) async {
    try {
      final id = await _repository.activeId();
      emit(ProfilesState(
        loaded: state.loaded,
        profiles: state.profiles,
        activeId: id,
        busy: state.busy,
        failures: state.failures,
      ));
    } on Exception {
      // Not on Android (tests, desktop preview).
    }
  }
}
