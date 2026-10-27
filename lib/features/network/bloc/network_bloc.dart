import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/network_repository.dart';

part 'network_event.dart';
part 'network_state.dart';

/// Wireless debugging and the internet kill switch.
class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc(this._repository) : super(const NetworkState()) {
    on<NetworkStarted>(_onStarted);
    on<NetworkRefreshed>(_onRefreshed);
    on<WirelessDebuggingSet>(_onWirelessDebuggingSet);
    on<KillSwitchSet>(_onKillSwitchSet);
    on<AllowedAppsChanged>(_onAllowedAppsChanged);
    on<InstalledAppsRequested>(_onInstalledAppsRequested);
  }

  final NetworkRepository _repository;

  Future<void> _onStarted(NetworkStarted event, Emitter<NetworkState> emit) async {
    emit(state.copyWith(allowedApps: await _repository.loadAllowedApps()));
    await _refresh(emit);
  }

  Future<void> _onRefreshed(NetworkRefreshed event, Emitter<NetworkState> emit) => _refresh(emit);

  Future<void> _onWirelessDebuggingSet(WirelessDebuggingSet event, Emitter<NetworkState> emit) async {
    final ok = await _repository.setWirelessDebugging(event.on);
    if (!ok) emit(state.copyWith(failures: state.failures + 1));
    // adbd needs a moment to pick its port before the address is complete.
    if (event.on) await Future<void>.delayed(const Duration(milliseconds: 800));
    await _refresh(emit);
  }

  Future<void> _onKillSwitchSet(KillSwitchSet event, Emitter<NetworkState> emit) async {
    emit(state.copyWith(killSwitchBusy: true));
    final ok = await _repository.setKillSwitch(event.on);
    emit(state.copyWith(killSwitchBusy: false, failures: ok ? null : state.failures + 1));
    await _refresh(emit);
  }

  Future<void> _onAllowedAppsChanged(AllowedAppsChanged event, Emitter<NetworkState> emit) async {
    emit(state.copyWith(allowedApps: event.packages));
    await _repository.saveAllowedApps(event.packages);
  }

  Future<void> _onInstalledAppsRequested(InstalledAppsRequested event, Emitter<NetworkState> emit) async {
    if (state.installedApps != null) return;
    try {
      emit(state.copyWith(installedApps: await _repository.loadInstalledApps()));
    } on Exception {
      emit(state.copyWith(installedApps: const []));
    }
  }

  Future<void> _refresh(Emitter<NetworkState> emit) async {
    try {
      emit(state.copyWith(status: await _repository.readStatus()));
    } on Exception {
      // Not on Android (tests, desktop preview).
    }
  }
}
