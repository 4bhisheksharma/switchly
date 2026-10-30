import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/public_mode_models.dart';

sealed class PublicModeEvent extends Equatable {
  const PublicModeEvent();

  @override
  List<Object?> get props => [];
}

final class PublicModeStarted extends PublicModeEvent {
  const PublicModeStarted();
}

final class PublicModeRefreshed extends PublicModeEvent {
  const PublicModeRefreshed();
}

final class PublicModeConfigUpdated extends PublicModeEvent {
  const PublicModeConfigUpdated(this.config);
  final PublicModeConfig config;

  @override
  List<Object?> get props => [config];
}

final class PublicModeActivateRequested extends PublicModeEvent {
  const PublicModeActivateRequested();
}

final class PublicModeDeactivateRequested extends PublicModeEvent {
  const PublicModeDeactivateRequested();
}

final class PublicModePermissionsChecked extends PublicModeEvent {
  const PublicModePermissionsChecked();
}

class PublicModeState extends Equatable {
  const PublicModeState({
    this.config = const PublicModeConfig(),
    this.active = false,
    this.endsAt = 0,
    this.hasUsageAccess = false,
    this.canDrawOverlays = false,
    this.hasDndAccess = false,
    this.isXiaomiDevice = false,
    this.hasMiuiPopupPermission = true,
    this.isIgnoringBattery = true,
    this.loading = false,
    this.launchableApps = const [],
  });

  final PublicModeConfig config;
  final bool active;
  final int endsAt;
  final bool hasUsageAccess;
  final bool canDrawOverlays;
  final bool hasDndAccess;
  final bool isXiaomiDevice;
  final bool hasMiuiPopupPermission;
  final bool isIgnoringBattery;
  final bool loading;
  final List<({String package, String label, Uint8List icon})> launchableApps;

  int get remainingSeconds {
    if (!active || endsAt <= 0) return 0;
    final remaining = (endsAt - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return remaining > 0 ? remaining : 0;
  }

  String get formattedRemainingTime {
    final secs = remainingSeconds;
    if (secs <= 0) return 'Ending shortly';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  PublicModeState copyWith({
    PublicModeConfig? config,
    bool? active,
    int? endsAt,
    bool? hasUsageAccess,
    bool? canDrawOverlays,
    bool? hasDndAccess,
    bool? isXiaomiDevice,
    bool? hasMiuiPopupPermission,
    bool? isIgnoringBattery,
    bool? loading,
    List<({String package, String label, Uint8List icon})>? launchableApps,
  }) {
    return PublicModeState(
      config: config ?? this.config,
      active: active ?? this.active,
      endsAt: endsAt ?? this.endsAt,
      hasUsageAccess: hasUsageAccess ?? this.hasUsageAccess,
      canDrawOverlays: canDrawOverlays ?? this.canDrawOverlays,
      hasDndAccess: hasDndAccess ?? this.hasDndAccess,
      isXiaomiDevice: isXiaomiDevice ?? this.isXiaomiDevice,
      hasMiuiPopupPermission: hasMiuiPopupPermission ?? this.hasMiuiPopupPermission,
      isIgnoringBattery: isIgnoringBattery ?? this.isIgnoringBattery,
      loading: loading ?? this.loading,
      launchableApps: launchableApps ?? this.launchableApps,
    );
  }

  @override
  List<Object?> get props => [
        config,
        active,
        endsAt,
        hasUsageAccess,
        canDrawOverlays,
        hasDndAccess,
        isXiaomiDevice,
        hasMiuiPopupPermission,
        isIgnoringBattery,
        loading,
        launchableApps,
      ];
}

class PublicModeBloc extends Bloc<PublicModeEvent, PublicModeState> {
  PublicModeBloc(this._repository) : super(const PublicModeState()) {
    on<PublicModeStarted>(_onStarted);
    on<PublicModeRefreshed>(_onRefreshed);
    on<PublicModeConfigUpdated>(_onConfigUpdated);
    on<PublicModeActivateRequested>(_onActivateRequested);
    on<PublicModeDeactivateRequested>(_onDeactivateRequested);
    on<PublicModePermissionsChecked>(_onPermissionsChecked);
  }

  final PublicModeRepository _repository;

  Future<void> _onStarted(PublicModeStarted event, Emitter<PublicModeState> emit) async {
    emit(state.copyWith(loading: true));
    final config = await _repository.loadConfig();
    final nativeState = await _repository.getState();
    emit(state.copyWith(
      config: config,
      active: nativeState.active,
      endsAt: nativeState.endsAt,
      hasUsageAccess: nativeState.hasUsageAccess,
      canDrawOverlays: nativeState.canDrawOverlays,
      hasDndAccess: nativeState.hasDndAccess,
      isXiaomiDevice: nativeState.isXiaomiDevice,
      hasMiuiPopupPermission: nativeState.hasMiuiPopupPermission,
      isIgnoringBattery: nativeState.isIgnoringBattery,
      loading: false,
    ));

    // Asynchronously load launchable apps
    try {
      final apps = await _repository.getLaunchableApps();
      emit(state.copyWith(launchableApps: apps));
    } catch (_) {}
  }

  Future<void> _onRefreshed(PublicModeRefreshed event, Emitter<PublicModeState> emit) async {
    final nativeState = await _repository.getState();
    final config = await _repository.loadConfig();
    emit(state.copyWith(
      config: config,
      active: nativeState.active,
      endsAt: nativeState.endsAt,
      hasUsageAccess: nativeState.hasUsageAccess,
      canDrawOverlays: nativeState.canDrawOverlays,
      hasDndAccess: nativeState.hasDndAccess,
      isXiaomiDevice: nativeState.isXiaomiDevice,
      hasMiuiPopupPermission: nativeState.hasMiuiPopupPermission,
      isIgnoringBattery: nativeState.isIgnoringBattery,
    ));
  }

  Future<void> _onConfigUpdated(
      PublicModeConfigUpdated event, Emitter<PublicModeState> emit) async {
    await _repository.saveConfig(event.config);
    emit(state.copyWith(config: event.config));
  }

  Future<void> _onActivateRequested(
      PublicModeActivateRequested event, Emitter<PublicModeState> emit) async {
    emit(state.copyWith(loading: true));
    await _repository.saveConfig(state.config);
    final ok = await _repository.activate();
    final nativeState = await _repository.getState();
    emit(state.copyWith(
      active: ok && nativeState.active,
      endsAt: nativeState.endsAt,
      loading: false,
    ));
  }

  Future<void> _onDeactivateRequested(
      PublicModeDeactivateRequested event, Emitter<PublicModeState> emit) async {
    emit(state.copyWith(loading: true));
    await _repository.deactivate();
    final nativeState = await _repository.getState();
    emit(state.copyWith(
      active: nativeState.active,
      endsAt: nativeState.endsAt,
      loading: false,
    ));
  }

  Future<void> _onPermissionsChecked(
      PublicModePermissionsChecked event, Emitter<PublicModeState> emit) async {
    final nativeState = await _repository.getState();
    emit(state.copyWith(
      hasUsageAccess: nativeState.hasUsageAccess,
      canDrawOverlays: nativeState.canDrawOverlays,
      hasDndAccess: nativeState.hasDndAccess,
      isXiaomiDevice: nativeState.isXiaomiDevice,
      hasMiuiPopupPermission: nativeState.hasMiuiPopupPermission,
      isIgnoringBattery: nativeState.isIgnoringBattery,
    ));
  }
}
