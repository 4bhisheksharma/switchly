import 'package:equatable/equatable.dart';
import '../models/update_info.dart';

sealed class UpdateState extends Equatable {
  const UpdateState({this.currentVersion = ''});

  final String currentVersion;

  @override
  List<Object?> get props => [currentVersion];
}

class UpdateInitial extends UpdateState {
  const UpdateInitial({super.currentVersion});
}

class UpdateChecking extends UpdateState {
  const UpdateChecking({super.currentVersion});
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable({
    required this.updateInfo,
    required super.currentVersion,
    this.canInstall = true,
  });

  final AppUpdateInfo updateInfo;
  final bool canInstall;

  @override
  List<Object?> get props => [currentVersion, updateInfo, canInstall];
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate({
    required super.currentVersion,
    required this.latestVersion,
    required this.checkedAt,
  });

  final String latestVersion;
  final DateTime checkedAt;

  @override
  List<Object?> get props => [currentVersion, latestVersion, checkedAt];
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading({
    required this.updateInfo,
    required super.currentVersion,
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final AppUpdateInfo updateInfo;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;

  String get formattedProgress {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totMb = totalBytes > 0 ? (totalBytes / (1024 * 1024)).toStringAsFixed(1) : '?';
    return '$pct% • $recMb / $totMb MB';
  }

  @override
  List<Object?> get props => [currentVersion, updateInfo, progress, receivedBytes, totalBytes];
}

class UpdateDownloaded extends UpdateState {
  const UpdateDownloaded({
    required this.updateInfo,
    required super.currentVersion,
    required this.apkPath,
    this.canInstall = true,
  });

  final AppUpdateInfo updateInfo;
  final String apkPath;
  final bool canInstall;

  @override
  List<Object?> get props => [currentVersion, updateInfo, apkPath, canInstall];
}

class UpdateError extends UpdateState {
  const UpdateError({
    required this.message,
    super.currentVersion,
  });

  final String message;

  @override
  List<Object?> get props => [currentVersion, message];
}
