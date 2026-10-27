/// Simple key-value storage wrapper used across the app.
///
/// The default implementation keeps values in memory. Swap the body for a
/// persistent backend (e.g. shared_preferences or hive) without changing any
/// of the calling code.
class AppStorage {
  AppStorage._();

  static final AppStorage instance = AppStorage._();

  final Map<String, String> _box = <String, String>{};

  Future<void> write(String key, String value) async {
    _box[key] = value;
  }

  Future<String?> read(String key) async {
    return _box[key];
  }

  Future<bool> contains(String key) async {
    return _box.containsKey(key);
  }

  Future<void> remove(String key) async {
    _box.remove(key);
  }

  Future<void> clear() async {
    _box.clear();
  }
}
