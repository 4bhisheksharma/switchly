/// SharedPreferences keys read by the Kotlin tiles. Keep in sync with `PrefKeys` in
/// android/.../core/SharedConfig.kt.
///
/// Write these with the legacy `SharedPreferences` API: it stores values in the
/// `FlutterSharedPreferences` file (prefixed with `flutter.`) that Kotlin reads. Store
/// anything structured as a JSON string.
abstract final class PrefKeys {
  /// JSON array of `{"name": String, "host": String}`.
  static const dnsProviders = 'dns_providers';
}
