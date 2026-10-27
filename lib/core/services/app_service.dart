import 'app_update_service.dart';

class AppService {
  Future<void> bootstrap() async {
    // TODO: initialize app-level services here.

    // Prompts for a Play Store update on Android; no-op elsewhere.
    await AppUpdateService.instance.checkForUpdate();
  }
}
