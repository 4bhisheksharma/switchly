/// Central application configuration, versioning metadata, and external resource URLs.
abstract final class AppConfig {
  /// App version name, matching pubspec.yaml.
  static const String versionName = '0.0.10';

  /// App version code, matching pubspec.yaml.
  static const int versionCode = 10;

  /// Full version string (e.g. "0.0.10+10").
  static const String fullVersion = '$versionName+$versionCode';

  /// Official hosted Privacy Policy URL.
  static const String privacyPolicyUrl = 'https://app.abhishek-sharma.com.np/switchly/privacy';

  /// Official repository LICENSE URL (GPL-3.0).
  static const String licenseUrl = 'https://github.com/4bhisheksharma/switchly/blob/main/LICENSE';

  /// Official repository URL on GitHub.
  static const String githubRepoUrl = 'https://github.com/4bhisheksharma/switchly';
}

