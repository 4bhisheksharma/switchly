import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/display_models.dart';
import '../data/display_repository.dart';

part 'display_event.dart';
part 'display_state.dart';

/// Grayscale, animation speed and font size: live system state plus the tiles' cycles.
class DisplayBloc extends Bloc<DisplayEvent, DisplayState> {
  DisplayBloc(this._repository) : super(const DisplayState()) {
    on<DisplayStarted>(_onStarted);
    on<DisplayRefreshed>(_onRefreshed);
    on<GrayscaleSet>(_onGrayscaleSet);
    on<AnimationSpeedSet>(_onAnimationSpeedSet);
    on<AnimationCycleSpeedToggled>(_onCycleSpeedToggled);
    on<FontScaleSet>(_onFontScaleSet);
    on<FontCycleScaleToggled>(_onFontCycleScaleToggled);
  }

  final DisplayRepository _repository;

  Future<void> _onStarted(DisplayStarted event, Emitter<DisplayState> emit) async {
    final config = await _repository.loadAnimationConfig();
    final fontConfig = await _repository.loadFontConfig();
    emit(state.copyWith(status: DisplayStatus.ready, animationConfig: config, fontConfig: fontConfig));
    await _refresh(emit);
  }

  Future<void> _onRefreshed(DisplayRefreshed event, Emitter<DisplayState> emit) => _refresh(emit);

  Future<void> _onGrayscaleSet(GrayscaleSet event, Emitter<DisplayState> emit) async {
    // Optimistic: the switch moves immediately, then settles on what the system reports.
    emit(state.copyWith(grayscale: event.on));
    final ok = await _repository.setGrayscale(event.on);
    if (!ok) emit(state.copyWith(applyFailures: state.applyFailures + 1));
    await _refresh(emit);
  }

  Future<void> _onAnimationSpeedSet(AnimationSpeedSet event, Emitter<DisplayState> emit) async {
    emit(state.copyWith(applying: true));
    final ok = await _repository.setAnimationSpeed(event.speed);
    emit(state.copyWith(applying: false, applyFailures: ok ? null : state.applyFailures + 1));
    await _refresh(emit);
  }

  Future<void> _onCycleSpeedToggled(AnimationCycleSpeedToggled event, Emitter<DisplayState> emit) async {
    final config = state.animationConfig;
    if (config.includes(event.speed) && !config.canRemove) return;
    final updated = config.toggled(event.speed);
    emit(state.copyWith(animationConfig: updated));
    await _repository.saveAnimationConfig(updated);
  }

  Future<void> _onFontScaleSet(FontScaleSet event, Emitter<DisplayState> emit) async {
    emit(state.copyWith(fontScale: event.scale));
    final ok = await _repository.setFontScale(event.scale);
    if (!ok) emit(state.copyWith(applyFailures: state.applyFailures + 1));
    await _refresh(emit);
  }

  Future<void> _onFontCycleScaleToggled(FontCycleScaleToggled event, Emitter<DisplayState> emit) async {
    final config = state.fontConfig;
    if (config.includes(event.scale) && !config.canRemove) return;
    final updated = config.toggled(event.scale);
    emit(state.copyWith(fontConfig: updated));
    await _repository.saveFontConfig(updated);
  }

  Future<void> _refresh(Emitter<DisplayState> emit) async {
    try {
      final live = await _repository.readLive();
      emit(state.copyWith(grayscale: live.grayscale, scales: live.scales, fontScale: live.fontScale));
    } on Exception {
      // Not on Android (tests, desktop preview).
    }
  }
}
