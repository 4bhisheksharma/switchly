import 'dart:math';

/// Holds metadata about a GitHub release asset and version.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.tagName,
    required this.versionName,
    required this.releaseTitle,
    required this.changelog,
    required this.publishedAt,
    required this.apkName,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    required this.htmlUrl,
  });

  final String tagName;
  final String versionName;
  final String releaseTitle;
  final String changelog;
  final DateTime publishedAt;
  final String apkName;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final String htmlUrl;

  /// Returns true if [versionName] is strictly higher than [currentVersion].
  bool isNewerThan(String currentVersion) {
    return compareVersions(versionName, currentVersion) > 0;
  }

  /// Compares two semver strings like "0.0.3" vs "0.0.2".
  /// Returns > 0 if v1 > v2, 0 if v1 == v2, < 0 if v1 < v2.
  static int compareVersions(String v1, String v2) {
    final clean1 = _extractNumbers(v1);
    final clean2 = _extractNumbers(v2);
    final maxLen = max(clean1.length, clean2.length);

    for (var i = 0; i < maxLen; i++) {
      final num1 = i < clean1.length ? clean1[i] : 0;
      final num2 = i < clean2.length ? clean2[i] : 0;
      if (num1 != num2) {
        return num1.compareTo(num2);
      }
    }
    return 0;
  }

  static List<int> _extractNumbers(String version) {
    // Strip leading 'v', suffixes like '+1' or '-beta'
    final mainPart = version.split('+').first.split('-').first.replaceAll(RegExp(r'[^0-9.]'), '');
    return mainPart
        .split('.')
        .where((segment) => segment.isNotEmpty)
        .map((segment) => int.tryParse(segment) ?? 0)
        .toList();
  }

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory AppUpdateInfo.fromGitHubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String?) ?? '';
    final cleanVersion = tag.replaceFirst(RegExp(r'^[vV]'), '');
    final title = (json['name'] as String?) ?? tag;
    final body = (json['body'] as String?) ?? 'No release notes provided.';
    final htmlUrl = (json['html_url'] as String?) ?? '';

    DateTime published;
    try {
      published = DateTime.parse(json['published_at'] as String);
    } catch (_) {
      published = DateTime.now();
    }

    String apkName = '';
    String apkUrl = '';
    int apkSize = 0;

    final assets = json['assets'] as List<dynamic>? ?? const [];
    for (final rawAsset in assets) {
      if (rawAsset is Map<String, dynamic>) {
        final name = (rawAsset['name'] as String?) ?? '';
        final contentType = (rawAsset['content_type'] as String?) ?? '';
        final downloadUrl = (rawAsset['browser_download_url'] as String?) ?? '';
        final size = (rawAsset['size'] as num?)?.toInt() ?? 0;

        if (name.endsWith('.apk') || contentType == 'application/vnd.android.package-archive') {
          apkName = name;
          apkUrl = downloadUrl;
          apkSize = size;
          break;
        }
      }
    }

    return AppUpdateInfo(
      tagName: tag,
      versionName: cleanVersion,
      releaseTitle: title,
      changelog: body.trim(),
      publishedAt: published,
      apkName: apkName,
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      htmlUrl: htmlUrl,
    );
  }
}
