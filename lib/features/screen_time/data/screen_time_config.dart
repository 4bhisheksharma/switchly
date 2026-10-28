import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Configuration for tracking a specific app's screen time.
class ScreenTimeConfig extends Equatable {
  const ScreenTimeConfig({
    required this.packageName,
    required this.appName,
    this.openAppOnTap = true,
  });

  final String packageName;
  final String appName;
  final bool openAppOnTap;

  ScreenTimeConfig copyWith({
    String? packageName,
    String? appName,
    bool? openAppOnTap,
  }) {
    return ScreenTimeConfig(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      openAppOnTap: openAppOnTap ?? this.openAppOnTap,
    );
  }

  Map<String, dynamic> toMap() => {
        'packageName': packageName,
        'appName': appName,
        'openAppOnTap': openAppOnTap,
      };

  String toJson() => jsonEncode(toMap());

  factory ScreenTimeConfig.fromMap(Map<String, dynamic> map) {
    return ScreenTimeConfig(
      packageName: (map['packageName'] as String?) ?? '',
      appName: (map['appName'] as String?) ?? '',
      openAppOnTap: (map['openAppOnTap'] as bool?) ?? true,
    );
  }

  factory ScreenTimeConfig.fromJson(String source) =>
      ScreenTimeConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [packageName, appName, openAppOnTap];
}
