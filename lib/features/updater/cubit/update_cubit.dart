import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/update_repository.dart';
import '../models/update_info.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({required this.repository}) : super(const UpdateInitial()) {
    _initVersion();
  }

  final UpdateRepository repository;
  String _cachedCurrentVersion = '0.0.3';

  Future<void> _initVersion() async {
    try {
      final info = await repository.getCurrentVersion();
      _cachedCurrentVersion = info.versionName;
      emit(UpdateInitial(currentVersion: _cachedCurrentVersion));
    } catch (_) {
      emit(UpdateInitial(currentVersion: _cachedCurrentVersion));
    }
  }

  /// Checks GitHub for the latest release.
  Future<void> checkForUpdate({bool forceShowAvailable = false}) async {
    emit(UpdateChecking(currentVersion: _cachedCurrentVersion));

    try {
      final versionInfo = await repository.getCurrentVersion();
      _cachedCurrentVersion = versionInfo.versionName;

      final latest = await repository.fetchLatestRelease();
      if (latest == null) {
        emit(UpdateUpToDate(
          currentVersion: _cachedCurrentVersion,
          latestVersion: _cachedCurrentVersion,
          checkedAt: DateTime.now(),
        ));
        return;
      }

      final isNewer = latest.isNewerThan(_cachedCurrentVersion) || forceShowAvailable;
      if (isNewer) {
        final canInstall = await repository.canInstallPackages();
        emit(UpdateAvailable(
          updateInfo: latest,
          currentVersion: _cachedCurrentVersion,
          canInstall: canInstall,
        ));
      } else {
        emit(UpdateUpToDate(
          currentVersion: _cachedCurrentVersion,
          latestVersion: latest.versionName,
          checkedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      emit(UpdateError(
        message: e is SocketException
            ? 'Unable to connect to GitHub. Check your internet connection.'
            : e.toString().replaceFirst('Exception: ', ''),
        currentVersion: _cachedCurrentVersion,
      ));
    }
  }

  /// Downloads the release APK with progress tracking, then triggers installation.
  Future<void> downloadAndInstall(AppUpdateInfo info) async {
    emit(UpdateDownloading(
      updateInfo: info,
      currentVersion: _cachedCurrentVersion,
      progress: 0.0,
      receivedBytes: 0,
      totalBytes: info.apkSizeBytes,
    ));

    try {
      final apkPath = await repository.downloadApk(
        info.apkDownloadUrl,
        onProgress: (received, total) {
          final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          emit(UpdateDownloading(
            updateInfo: info,
            currentVersion: _cachedCurrentVersion,
            progress: progress,
            receivedBytes: received,
            totalBytes: total,
          ));
        },
      );

      final canInstall = await repository.canInstallPackages();
      emit(UpdateDownloaded(
        updateInfo: info,
        currentVersion: _cachedCurrentVersion,
        apkPath: apkPath,
        canInstall: canInstall,
      ));

      // Trigger the install prompt immediately
      await repository.installApk(apkPath);
    } catch (e) {
      emit(UpdateError(
        message: 'Download failed: ${e.toString().replaceFirst('Exception: ', '')}',
        currentVersion: _cachedCurrentVersion,
      ));
    }
  }

  /// Manually triggers installation if already downloaded.
  Future<void> installApk(String apkPath) async {
    try {
      await repository.installApk(apkPath);
    } catch (e) {
      emit(UpdateError(
        message: 'Could not launch installer: $e',
        currentVersion: _cachedCurrentVersion,
      ));
    }
  }

  /// Opens Android's system screen to allow Switchly to install APKs.
  Future<void> openInstallPermissionSettings() async {
    await repository.openInstallPermissionSettings();
  }

  /// Refreshes install permission status when returning from settings.
  Future<void> checkInstallPermission() async {
    final state = this.state;
    final canInstall = await repository.canInstallPackages();
    if (state is UpdateAvailable) {
      emit(UpdateAvailable(
        updateInfo: state.updateInfo,
        currentVersion: state.currentVersion,
        canInstall: canInstall,
      ));
    } else if (state is UpdateDownloaded) {
      emit(UpdateDownloaded(
        updateInfo: state.updateInfo,
        currentVersion: state.currentVersion,
        apkPath: state.apkPath,
        canInstall: canInstall,
      ));
    }
  }
}
