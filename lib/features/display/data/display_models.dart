import 'package:equatable/equatable.dart';

/// Speeds offered in the app, matching common Developer options values.
const animationSpeeds = <double>[0, 0.5, 1, 1.5, 2];

bool sameSpeed(double a, double b) => (a - b).abs() < 0.01;

String speedLabel(double speed) {
  if (sameSpeed(speed, 0)) return 'Off';
  final whole = sameSpeed(speed, speed.roundToDouble());
  return '${whole ? speed.round() : speed}×';
}

String speedDescription(double speed) => switch (speed) {
      _ when sameSpeed(speed, 0) => 'No animations at all',
      _ when speed < 1 => 'Animations play faster',
      _ when sameSpeed(speed, 1) => 'System default',
      _ => 'Animations play slower',
    };

/// The tile's speed cycle. Mirrors `AnimationScale.cycle` in Kotlin.
class AnimationConfig extends Equatable {
  const AnimationConfig(this.speeds);

  factory AnimationConfig.fromJson(Map<String, Object?> json) => AnimationConfig([
        for (final s in json['speeds'] as List? ?? const []) (s as num).toDouble(),
      ]);

  /// Used until the user edits the cycle. Keep in sync with DEFAULT_CYCLE in AnimationScale.kt.
  static const defaults = AnimationConfig([0, 0.5, 1]);

  static const minCycleLength = 2;

  /// In tap order (always ascending).
  final List<double> speeds;

  bool includes(double speed) => speeds.any((s) => sameSpeed(s, speed));

  bool get canRemove => speeds.length > minCycleLength;

  AnimationConfig toggled(double speed) => AnimationConfig(
        includes(speed) ? speeds.where((s) => !sameSpeed(s, speed)).toList() : ([...speeds, speed]..sort()),
      );

  Map<String, Object?> toJson() => {'speeds': speeds};

  @override
  List<Object?> get props => [speeds];
}

/// The three Developer options animation scales.
class AnimationScales extends Equatable {
  const AnimationScales(this.window, this.transition, this.animator);

  final double window;
  final double transition;
  final double animator;

  /// The shared speed, or null if they were set to different values in Developer options.
  double? get uniform => sameSpeed(window, transition) && sameSpeed(window, animator) ? window : null;

  @override
  List<Object?> get props => [window, transition, animator];
}
