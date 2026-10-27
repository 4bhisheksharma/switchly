part of 'setup_bloc.dart';

enum SetupStatus { loading, ready, failure }

final class SetupState extends Equatable {
  const SetupState({
    this.status = SetupStatus.loading,
    this.device,
    this.hasPermission = false,
    this.isChecking = false,
  });

  final SetupStatus status;

  /// Non-null once [status] is [SetupStatus.ready].
  final DeviceInfo? device;
  final bool hasPermission;
  final bool isChecking;

  String get adbCommand =>
      'adb shell pm grant ${device?.packageName} android.permission.WRITE_SECURE_SETTINGS';

  SetupState copyWith({
    SetupStatus? status,
    DeviceInfo? device,
    bool? hasPermission,
    bool? isChecking,
  }) {
    return SetupState(
      status: status ?? this.status,
      device: device ?? this.device,
      hasPermission: hasPermission ?? this.hasPermission,
      isChecking: isChecking ?? this.isChecking,
    );
  }

  @override
  List<Object?> get props => [status, device?.packageName, device?.sdkInt, hasPermission, isChecking];
}
