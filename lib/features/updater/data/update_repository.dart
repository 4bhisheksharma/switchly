import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/platform/qs_channel.dart';
import '../models/update_info.dart';

/// Repository that connects to the GitHub API, checks for updates,
/// streams APK downloads with live progress, and triggers installation.
class UpdateRepository {
  UpdateRepository({
    required this.channel,
    this.repoOwner = '4bhisheksharma',
    this.repoName = 'switchly',
  });

  final QsChannel channel;
  final String repoOwner;
  final String repoName;

  /// Fetches runtime app version information from the Android Package Manager.
  Future<({String versionName, int versionCode})> getCurrentVersion() =>
      channel.getAppVersion();

  /// Checks the latest release from GitHub API.
  Future<AppUpdateInfo?> fetchLatestRelease() async {
    final uri = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'Switchly-Android-App');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        return AppUpdateInfo.fromGitHubJson(json);
      } else if (response.statusCode == 404) {
        // No releases found
        return null;
      } else {
        throw HttpException(
          'GitHub API returned HTTP ${response.statusCode}',
          uri: uri,
        );
      }
    } finally {
      client.close();
    }
  }

  /// Downloads the APK to the application cache directory with live progress callbacks.
  Future<String> downloadApk(
    String apkUrl, {
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    final client = HttpClient()
      ..autoUncompress = true
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri.parse(apkUrl);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'Switchly-Android-App');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Download failed with HTTP ${response.statusCode}', uri: uri);
      }

      final totalBytes = response.contentLength;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/switchly-update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      var receivedBytes = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();

      return apkFile.path;
    } finally {
      client.close();
    }
  }

  /// Verifies if Switchly has system permission to request package installs.
  Future<bool> canInstallPackages() => channel.canInstallPackages();

  /// Opens the Android "Install unknown apps" settings page for Switchly.
  Future<bool> openInstallPermissionSettings() => channel.openInstallPermissionSettings();

  /// Hands the downloaded APK off to the Android package installer.
  Future<bool> installApk(String filePath) => channel.installApk(filePath);
}
