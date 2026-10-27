import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/power_models.dart';

final class CaffeineState extends Equatable {
  const CaffeineState({this.status = const CaffeineStatus(), this.config = CaffeineConfig.defaults});

  final CaffeineStatus status;
  final CaffeineConfig config;

  CaffeineState copyWith({CaffeineStatus? status, CaffeineConfig? config}) =>
      CaffeineState(status: status ?? this.status, config: config ?? this.config);

  @override
  List<Object?> get props => [status, config];
}

/// Caffeine on/off plus the tile's duration cycle.
class CaffeineCubit extends Cubit<CaffeineState> {
  CaffeineCubit(this._repository) : super(const CaffeineState());

  final PowerRepository _repository;

  /// Re-reads when a timed session ends, so the UI flips to off on its own.
  Timer? _endTimer;

  @override
  void onChange(Change<CaffeineState> change) {
    super.onChange(change);
    _endTimer?.cancel();
    final endsAt = change.nextState.status.endsAt;
    if (endsAt != null) {
      _endTimer = Timer(endsAt.difference(DateTime.now()) + const Duration(seconds: 1), refresh);
    }
  }

  @override
  Future<void> close() {
    _endTimer?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(state.copyWith(config: await _repository.loadCaffeineConfig()));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      emit(state.copyWith(status: await _repository.caffeine()));
    } on Exception {
      // Not on Android (tests, desktop preview).
    }
  }

  Future<void> start(int minutes) async => emit(state.copyWith(status: await _repository.startCaffeine(minutes)));

  Future<void> stop() async => emit(state.copyWith(status: await _repository.stopCaffeine()));

  Future<void> toggleDuration(int minutes) => _save(state.config.toggled(minutes));

  Future<void> setStopOnLock(bool value) => _save(state.config.withStopOnLock(value));

  Future<void> _save(CaffeineConfig config) async {
    emit(state.copyWith(config: config));
    await _repository.saveCaffeineConfig(config);
  }
}

/// Live battery readings, polled while the app is in the foreground.
class BatteryCubit extends Cubit<BatteryStatus?> {
  BatteryCubit(this._repository) : super(null);

  final PowerRepository _repository;
  Timer? _timer;

  void resume() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    try {
      final status = await _repository.battery();
      if (!isClosed) emit(status);
    } on Exception {
      // Not on Android (tests, desktop preview).
    }
  }

  @override
  Future<void> close() {
    pause();
    return super.close();
  }
}
