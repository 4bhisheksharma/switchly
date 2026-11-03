import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/volume_models.dart';
import '../data/volume_repository.dart';

enum VolumeStatus { initial, loading, success, failure }

sealed class VolumeEvent extends Equatable {
  const VolumeEvent();

  @override
  List<Object?> get props => [];
}

final class VolumeStarted extends VolumeEvent {
  const VolumeStarted();
}

final class VolumeRefreshed extends VolumeEvent {
  const VolumeRefreshed();
}

final class VolumeLevelChanged extends VolumeEvent {
  const VolumeLevelChanged({
    required this.stream,
    required this.level,
    this.playSound = false,
  });

  final String stream;
  final int level;
  final bool playSound;

  @override
  List<Object?> get props => [stream, level, playSound];
}

final class VolumeStepAdjusted extends VolumeEvent {
  const VolumeStepAdjusted({
    required this.stream,
    required this.increase,
  });

  final String stream;
  final bool increase;

  @override
  List<Object?> get props => [stream, increase];
}

final class VolumeExternalChanged extends VolumeEvent {
  const VolumeExternalChanged(this.snapshot);
  final VolumeSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

final class VolumePresetChanged extends VolumeEvent {
  const VolumePresetChanged(this.percent);
  final int percent;

  @override
  List<Object?> get props => [percent];
}

final class VolumeRingerModeChanged extends VolumeEvent {
  const VolumeRingerModeChanged(this.mode);
  final RingerMode mode;

  @override
  List<Object?> get props => [mode];
}

final class VolumeSystemUiRequested extends VolumeEvent {
  const VolumeSystemUiRequested();
}

final class VolumeSoundSettingsRequested extends VolumeEvent {
  const VolumeSoundSettingsRequested();
}

class VolumeState extends Equatable {
  const VolumeState({
    this.status = VolumeStatus.initial,
    this.snapshot = VolumeSnapshot.fallback,
  });

  final VolumeStatus status;
  final VolumeSnapshot snapshot;

  VolumeState copyWith({
    VolumeStatus? status,
    VolumeSnapshot? snapshot,
  }) =>
      VolumeState(
        status: status ?? this.status,
        snapshot: snapshot ?? this.snapshot,
      );

  @override
  List<Object?> get props => [status, snapshot];
}

class VolumeBloc extends Bloc<VolumeEvent, VolumeState> {
  VolumeBloc(this._repository) : super(const VolumeState()) {
    on<VolumeStarted>(_onStarted);
    on<VolumeRefreshed>(_onRefreshed);
    on<VolumeLevelChanged>(_onLevelChanged);
    on<VolumeStepAdjusted>(_onStepAdjusted);
    on<VolumePresetChanged>(_onPresetChanged);
    on<VolumeRingerModeChanged>(_onRingerModeChanged);
    on<VolumeSystemUiRequested>(_onSystemUiRequested);
    on<VolumeSoundSettingsRequested>(_onSoundSettingsRequested);
    on<VolumeExternalChanged>(_onExternalChanged);

    _volumeSub = _repository.channel.onVolumeChanged.listen((map) {
      if (map.isNotEmpty) {
        add(VolumeExternalChanged(VolumeSnapshot.fromMap(map)));
      }
    });
  }

  final VolumeRepository _repository;
  StreamSubscription<Map<String, dynamic>>? _volumeSub;

  @override
  Future<void> close() {
    _volumeSub?.cancel();
    return super.close();
  }

  void _onExternalChanged(VolumeExternalChanged event, Emitter<VolumeState> emit) {
    emit(state.copyWith(snapshot: event.snapshot));
  }

  Future<void> _onStepAdjusted(VolumeStepAdjusted event, Emitter<VolumeState> emit) async {
    final streamState = switch (event.stream) {
      'music' => state.snapshot.music,
      'ring' => state.snapshot.ring,
      'notification' => state.snapshot.notification,
      'alarm' => state.snapshot.alarm,
      'call' => state.snapshot.call,
      _ => state.snapshot.music,
    };
    final nextLevel = event.increase
        ? (streamState.current + 1).clamp(streamState.min, streamState.max)
        : (streamState.current - 1).clamp(streamState.min, streamState.max);
    add(VolumeLevelChanged(stream: event.stream, level: nextLevel, playSound: true));
  }

  Future<void> _onStarted(VolumeStarted event, Emitter<VolumeState> emit) async {
    final levels = await _repository.getLevels();
    emit(state.copyWith(status: VolumeStatus.success, snapshot: levels));
  }

  Future<void> _onRefreshed(VolumeRefreshed event, Emitter<VolumeState> emit) async {
    final levels = await _repository.getLevels();
    emit(state.copyWith(snapshot: levels));
  }

  Future<void> _onLevelChanged(VolumeLevelChanged event, Emitter<VolumeState> emit) async {
    // Optimistic update
    final currentSnap = state.snapshot;
    final updatedStream = switch (event.stream) {
      'music' => currentSnap.music.copyWith(
          current: event.level,
          percent: _calcPercent(event.level, currentSnap.music.min, currentSnap.music.max),
        ),
      'ring' => currentSnap.ring.copyWith(
          current: event.level,
          percent: _calcPercent(event.level, currentSnap.ring.min, currentSnap.ring.max),
        ),
      'notification' => currentSnap.notification.copyWith(
          current: event.level,
          percent: _calcPercent(event.level, currentSnap.notification.min, currentSnap.notification.max),
        ),
      'alarm' => currentSnap.alarm.copyWith(
          current: event.level,
          percent: _calcPercent(event.level, currentSnap.alarm.min, currentSnap.alarm.max),
        ),
      'call' => currentSnap.call.copyWith(
          current: event.level,
          percent: _calcPercent(event.level, currentSnap.call.min, currentSnap.call.max),
        ),
      _ => currentSnap.music,
    };

    final newSnapshot = VolumeSnapshot(
      music: event.stream == 'music' ? updatedStream : currentSnap.music,
      ring: event.stream == 'ring' ? updatedStream : currentSnap.ring,
      notification: event.stream == 'notification' ? updatedStream : currentSnap.notification,
      alarm: event.stream == 'alarm' ? updatedStream : currentSnap.alarm,
      call: event.stream == 'call' ? updatedStream : currentSnap.call,
      ringerMode: currentSnap.ringerMode,
    );
    emit(state.copyWith(snapshot: newSnapshot));

    await _repository.setVolume(event.stream, event.level, playSound: event.playSound);
  }

  Future<void> _onPresetChanged(VolumePresetChanged event, Emitter<VolumeState> emit) async {
    final music = state.snapshot.music;
    final range = (music.max - music.min).clamp(1, 100);
    final targetLevel = (music.min + (range * (event.percent / 100.0))).round();
    add(VolumeLevelChanged(stream: 'music', level: targetLevel));
  }

  Future<void> _onRingerModeChanged(VolumeRingerModeChanged event, Emitter<VolumeState> emit) async {
    final currentSnap = state.snapshot;
    emit(state.copyWith(
      snapshot: VolumeSnapshot(
        music: currentSnap.music,
        ring: currentSnap.ring,
        notification: currentSnap.notification,
        alarm: currentSnap.alarm,
        call: currentSnap.call,
        ringerMode: event.mode,
      ),
    ));
    await _repository.setRingerMode(event.mode);
    final fresh = await _repository.getLevels();
    emit(state.copyWith(snapshot: fresh));
  }

  Future<void> _onSystemUiRequested(VolumeSystemUiRequested event, Emitter<VolumeState> emit) async {
    await _repository.showSystemVolume();
  }

  Future<void> _onSoundSettingsRequested(VolumeSoundSettingsRequested event, Emitter<VolumeState> emit) async {
    await _repository.openSoundSettings();
  }

  int _calcPercent(int current, int min, int max) {
    if (max <= min) return 0;
    return (((current - min) / (max - min)) * 100).round().clamp(0, 100);
  }
}

