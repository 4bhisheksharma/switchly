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
      } else if (response.statusCode == 403) {
        throw const HttpException('GitHub API rate limit reached. Please try again later or view releases on GitHub.');
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

  /// Downloads the APK to an accessible cache directory with live progress callbacks.
  Future<String> downloadApk(
    String apkUrl, {
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    if (apkUrl.trim().isEmpty) {
      throw const FormatException('Release does not contain an APK download URL.');
    }

    final client = HttpClient()
      ..autoUncompress = true
      ..connectionTimeout = const Duration(seconds: 20);

    try {
      var currentUri = Uri.parse(apkUrl);
      HttpClientResponse response;
      var redirectCount = 0;
      const maxRedirects = 10;

      while (true) {
        final request = await client.getUrl(currentUri);
        request.headers.set(HttpHeaders.userAgentHeader, 'Switchly-Android-App');
        request.headers.set(HttpHeaders.acceptHeader, '*/*');
        request.followRedirects = false; // Manually handle redirects to S3 cleanly

        response = await request.close();

        if (response.isRedirect ||
            response.statusCode == HttpStatus.movedPermanently ||
            response.statusCode == HttpStatus.movedTemporarily ||
            response.statusCode == HttpStatus.seeOther ||
            response.statusCode == HttpStatus.temporaryRedirect ||
            response.statusCode == HttpStatus.permanentRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null || location.isEmpty) {
            throw HttpException('Redirect location missing', uri: currentUri);
          }
          currentUri = currentUri.resolve(location);
          await response.drain<void>();
          redirectCount++;
          if (redirectCount > maxRedirects) {
            throw HttpException('Too many redirects', uri: currentUri);
          }
          continue;
        }
        break;
      }

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Download failed with HTTP ${response.statusCode}', uri: currentUri);
      }

      final totalBytes = response.contentLength;

      // Prefer external cache directory so system package installer can access it without permission drops
      Directory storageDir;
      try {
        final extDirs = await getExternalCacheDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          storageDir = extDirs.first;
        } else {
          storageDir = await getTemporaryDirectory();
        }
      } catch (_) {
        storageDir = await getTemporaryDirectory();
      }

      final apkFile = File('${storageDir.path}/switchly-update.apk');

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

      if (!await apkFile.exists() || await apkFile.length() == 0) {
        throw const FileSystemException('Downloaded APK file is empty or missing.');
      }

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

  /// Opens an external URL in the default browser.
  Future<bool> openUrl(String url) => channel.openUrl(url);
}
