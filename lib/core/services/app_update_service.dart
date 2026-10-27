import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Prompts the user to update when a newer version is on the Play Store.
///
/// Uses Google Play's in-app updates API, so it only works on Android builds
/// installed from the Play Store. On every other platform it does nothing.
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  bool _checked = false;

  /// Checks for an update once per app launch.
  ///
  /// Set [immediate] to `true` for a blocking full-screen update (use it for
  /// critical releases). Otherwise the update downloads in the background and
  /// is installed when the download completes.
  Future<void> checkForUpdate({bool immediate = false}) async {
    if (_checked || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (immediate && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // Expected in debug or sideloaded builds where Play is unavailable.
      debugPrint('AppUpdateService: update check failed: $e');
    }
  }
}
