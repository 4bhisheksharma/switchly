import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mic_models.dart';
import '../data/mic_repository.dart';

sealed class MicEvent extends Equatable {
  const MicEvent();

  @override
  List<Object?> get props => [];
}

final class MicStarted extends MicEvent {
  const MicStarted();
}

final class MicRefreshed extends MicEvent {
  const MicRefreshed();
}

final class MicModeSelected extends MicEvent {
  const MicModeSelected(this.mode);

  final String mode;

  @override
  List<Object?> get props => [mode];
}

final class MicTestToggled extends MicEvent {
  const MicTestToggled();
}

final class MicLevelReceived extends MicEvent {
  const MicLevelReceived(this.level);

  final double level;

  @override
  List<Object?> get props => [level];
}

class MicBloc extends Bloc<MicEvent, MicState> {
  MicBloc(this._repository) : super(const MicState()) {
    on<MicStarted>(_onStarted);
    on<MicRefreshed>(_onRefreshed);
    on<MicModeSelected>(_onModeSelected);
    on<MicTestToggled>(_onTestToggled);
    on<MicLevelReceived>(_onLevelReceived);

    _levelSub = _repository.micLevels.listen((level) {
      add(MicLevelReceived(level));
    });
    _modeSub = _repository.micModeChanges.listen((_) {
      add(const MicRefreshed());
    });
  }

  final MicRepository _repository;
  StreamSubscription<double>? _levelSub;
  StreamSubscription<String>? _modeSub;

  Future<void> _onStarted(MicStarted event, Emitter<MicState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final loaded = await _repository.loadState();
      emit(loaded.copyWith(isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onRefreshed(MicRefreshed event, Emitter<MicState> emit) async {
    try {
      final loaded = await _repository.loadState();
      emit(loaded.copyWith(
        isTesting: state.isTesting,
        testLevel: state.testLevel,
      ));
    } catch (_) {}
  }

  Future<void> _onModeSelected(MicModeSelected event, Emitter<MicState> emit) async {
    // Optimistically update
    emit(state.copyWith(currentMode: event.mode));
    await _repository.setMode(event.mode);
    add(const MicRefreshed());
  }

  Future<void> _onTestToggled(MicTestToggled event, Emitter<MicState> emit) async {
    if (state.isTesting) {
      await _repository.stopMicTest();
      emit(state.copyWith(isTesting: false, testLevel: 0.0));
    } else {
      final success = await _repository.startMicTest();
      if (success) {
        emit(state.copyWith(isTesting: true));
      }
    }
  }

  void _onLevelReceived(MicLevelReceived event, Emitter<MicState> emit) {
    if (state.isTesting) {
      emit(state.copyWith(testLevel: event.level));
    }
  }

  @override
  Future<void> close() {
    _levelSub?.cancel();
    _modeSub?.cancel();
    if (state.isTesting) {
      _repository.stopMicTest();
    }
    return super.close();
  }
}
