/// SharedPreferences keys read by the Kotlin tiles. Keep in sync with `PrefKeys` in
/// android/.../core/SharedConfig.kt.
///
/// Write these with the legacy `SharedPreferences` API: it stores values in the
/// `FlutterSharedPreferences` file (prefixed with `flutter.`) that Kotlin reads. Store
/// anything structured as a JSON string.
abstract final class PrefKeys {
  /// JSON: `{"includeOff", "includeAutomatic", "providers": [{"id", "name", "host", "enabled"}]}`.
  static const dnsConfig = 'dns_config';

  /// JSON: `{"speeds": [double]}` in tap order.
  static const animationConfig = 'animation_config';

  /// JSON array of `{"id", "title", "text"}`.
  static const quickTexts = 'quick_texts';

  /// JSON: `{"allowedApps": [packageName]}`: apps that stay online.
  static const killSwitchConfig = 'kill_switch_config';

  /// JSON array of profiles; see lib/features/profiles/data/profile_models.dart.
  static const profiles = 'profiles';

  /// JSON: `{"nepali": bool}`: Devanagari or English for the BS date.
  static const bsConfig = 'bs_config';

  /// JSON array of `{"id", "name", "path"}`; path is an image in the app's files dir.
  static const paymentQrs = 'payment_qrs';

  /// JSON: `{"scales": [double]}` in tap order.
  static const fontConfig = 'font_config';

  /// JSON: `{"minutes": [int], "stopOnLock": bool}`; 0 minutes means no time limit.
  static const caffeineConfig = 'caffeine_config';

  /// bool: show a message at the top after a tile tap (closes the panel). Default true.
  static const showTileMessage = 'show_tile_message';
}
