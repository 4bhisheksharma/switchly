part of 'display_bloc.dart';

sealed class DisplayEvent extends Equatable {
  const DisplayEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the saved animation cycle and the live system state.
final class DisplayStarted extends DisplayEvent {
  const DisplayStarted();
}

/// Re-reads the live state (app resumed, or a tile changed it).
final class DisplayRefreshed extends DisplayEvent {
  const DisplayRefreshed();
}

final class GrayscaleSet extends DisplayEvent {
  const GrayscaleSet(this.on);

  final bool on;

  @override
  List<Object?> get props => [on];
}

/// Applies [speed] to all three animation scales now.
final class AnimationSpeedSet extends DisplayEvent {
  const AnimationSpeedSet(this.speed);

  final double speed;

  @override
  List<Object?> get props => [speed];
}

/// Applies the system font [scale] now.
final class FontScaleSet extends DisplayEvent {
  const FontScaleSet(this.scale);

  final double scale;

  @override
  List<Object?> get props => [scale];
}

/// Adds or removes [scale] from the font tile's cycle.
final class FontCycleScaleToggled extends DisplayEvent {
  const FontCycleScaleToggled(this.scale);

  final double scale;

  @override
  List<Object?> get props => [scale];
}

/// Adds or removes [speed] from the tile's cycle.
final class AnimationCycleSpeedToggled extends DisplayEvent {
  const AnimationCycleSpeedToggled(this.speed);

  final double speed;

  @override
  List<Object?> get props => [speed];
}
