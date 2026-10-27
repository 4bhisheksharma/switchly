part of 'display_bloc.dart';

enum DisplayStatus { loading, ready }

final class DisplayState extends Equatable {
  const DisplayState({
    this.status = DisplayStatus.loading,
    this.grayscale,
    this.scales,
    this.animationConfig = AnimationConfig.defaults,
    this.applying = false,
    this.applyFailures = 0,
  });

  final DisplayStatus status;

  /// Null until read, or when not running on Android.
  final bool? grayscale;
  final AnimationScales? scales;
  final AnimationConfig animationConfig;
  final bool applying;

  /// Incremented on each refused change, so the UI can react once per failure.
  final int applyFailures;

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
    bool? applying,
    int? applyFailures,
  }) {
    return DisplayState(
      status: status ?? this.status,
      grayscale: grayscale ?? this.grayscale,
      scales: scales ?? this.scales,
      animationConfig: animationConfig ?? this.animationConfig,
      applying: applying ?? this.applying,
      applyFailures: applyFailures ?? this.applyFailures,
    );
  }

  @override
  List<Object?> get props => [status, grayscale, scales, animationConfig, applying, applyFailures];
}
