class AppController {
  bool _initialized = false;

  bool get initialized => _initialized;

  void initialize() {
    _initialized = true;
  }
}
