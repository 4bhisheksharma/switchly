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

/// Font sizes offered in the app (Settings.System font_scale). Android's own slider goes up to
/// 130% before Android 14 and 200% from Android 14, so the larger ones are hidden on older versions.
const fontScales = <double>[0.85, 1, 1.15, 1.3, 1.5, 1.8, 2];

/// The largest size offered on [sdkInt].
double maxFontScale(int sdkInt) => sdkInt >= 34 ? 2 : 1.5;

String fontLabel(double scale) => '${(scale * 100).round()}%';

String fontDescription(double scale) => switch (scale) {
      _ when sameSpeed(scale, 1) => 'System default',
      _ when scale < 1 => 'Smaller',
      _ when scale <= 1.3 => 'Larger',
      _ => 'Much larger',
    };

/// The font tile's size cycle. Mirrors `FontScale.cycle` in Kotlin.
class FontConfig extends Equatable {
  const FontConfig(this.scales);

  factory FontConfig.fromJson(Map<String, Object?> json) => FontConfig([
        for (final s in json['scales'] as List? ?? const []) (s as num).toDouble(),
      ]);

  /// Used until the user edits the cycle. Keep in sync with DEFAULT_CYCLE in FontScale.kt.
  static const defaults = FontConfig([1, 1.3, 1.5]);

  static const minCycleLength = 2;

  /// In tap order (always ascending).
  final List<double> scales;

  bool includes(double scale) => scales.any((s) => sameSpeed(s, scale));

  bool get canRemove => scales.length > minCycleLength;

  FontConfig toggled(double scale) => FontConfig(
        includes(scale) ? scales.where((s) => !sameSpeed(s, scale)).toList() : ([...scales, scale]..sort()),
      );

  Map<String, Object?> toJson() => {'scales': scales};

  @override
  List<Object?> get props => [scales];
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
