import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/platform/qs_channel.dart';
import '../data/setup_repository.dart';

part 'setup_event.dart';
part 'setup_state.dart';

/// Tracks whether WRITE_SECURE_SETTINGS has been granted and basic device info.
///
/// There is no API to ask whether a tile has been added to Quick Settings, so tile
/// "status" is limited to the result of an add request (handled in the UI).
class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc(this._repository) : super(const SetupState()) {
    on<SetupStarted>(_onStarted);
    on<SetupPermissionCheckRequested>(_onPermissionCheckRequested);
  }

  final SetupRepository _repository;

  Future<void> _onStarted(SetupStarted event, Emitter<SetupState> emit) async {
    try {
      final device = await _repository.getDeviceInfo();
      final granted = await _repository.hasWriteSecureSettings();
      emit(state.copyWith(status: SetupStatus.ready, device: device, hasPermission: granted));
    } on Exception {
      // PlatformException / MissingPluginException, e.g. when not running on Android.
      emit(state.copyWith(status: SetupStatus.failure));
    }
  }

  Future<void> _onPermissionCheckRequested(
    SetupPermissionCheckRequested event,
    Emitter<SetupState> emit,
  ) async {
    if (state.status != SetupStatus.ready) return;
    emit(state.copyWith(isChecking: true));
    try {
      final granted = await _repository.hasWriteSecureSettings();
      emit(state.copyWith(hasPermission: granted, isChecking: false));
    } on Exception {
      emit(state.copyWith(isChecking: false));
    }
  }
}
