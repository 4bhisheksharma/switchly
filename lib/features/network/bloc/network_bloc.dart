import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/network_repository.dart';

part 'network_event.dart';
part 'network_state.dart';

/// Wireless debugging tile bloc.
class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc(this._repository) : super(const NetworkState()) {
    on<NetworkStarted>(_onStarted);
    on<NetworkRefreshed>(_onRefreshed);
    on<WirelessDebuggingSet>(_onWirelessDebuggingSet);
  }

  final NetworkRepository _repository;

  Future<void> _onStarted(NetworkStarted event, Emitter<NetworkState> emit) async {
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

  Future<void> _refresh(Emitter<NetworkState> emit) async {
    try {
      emit(state.copyWith(status: await _repository.readStatus()));
    } on Exception {
      // Not on Android (tests, desktop preview).
    }
  }
}
