part of 'display_bloc.dart';

enum DisplayStatus { loading, ready }

final class DisplayState extends Equatable {
  const DisplayState({
    this.status = DisplayStatus.loading,
    this.grayscale,
    this.scales,
    this.animationConfig = AnimationConfig.defaults,
    this.fontScale,
    this.fontConfig = FontConfig.defaults,
    this.applying = false,
    this.applyFailures = 0,
  });

  final DisplayStatus status;

  /// Null until read, or when not running on Android.
  final bool? grayscale;
  final AnimationScales? scales;
  final AnimationConfig animationConfig;

  /// Null until read, or when not running on Android.
  final double? fontScale;
  final FontConfig fontConfig;
  final bool applying;

  /// Incremented on each refused change, so the UI can react once per failure.
  final int applyFailures;

  bool get fontModified => fontScale != null && !sameSpeed(fontScale!, 1);

  /// The uniform speed, or null when unknown or the scales differ.
  double? get speed => scales?.uniform;

  /// True when animations aren't at the system default (1×), including mixed scales.
  bool get animationModified => scales != null && (speed == null || !sameSpeed(speed!, 1));

  String get speedText => switch (scales) {
        null => '—',
        final s when s.uniform == null => 'Custom',
        final s => speedLabel(s.uniform!),
      };

  DisplayState copyWith({
    DisplayStatus? status,
    bool? grayscale,
    AnimationScales? scales,
    AnimationConfig? animationConfig,
    double? fontScale,
    FontConfig? fontConfig,
    bool? applying,
    int? applyFailures,
  }) {
    return DisplayState(
      status: status ?? this.status,
      grayscale: grayscale ?? this.grayscale,
      scales: scales ?? this.scales,
      animationConfig: animationConfig ?? this.animationConfig,
      fontScale: fontScale ?? this.fontScale,
      fontConfig: fontConfig ?? this.fontConfig,
      applying: applying ?? this.applying,
      applyFailures: applyFailures ?? this.applyFailures,
    );
  }

  @override
  List<Object?> get props =>
      [status, grayscale, scales, animationConfig, fontScale, fontConfig, applying, applyFailures];
}
