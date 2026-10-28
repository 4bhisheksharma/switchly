import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Configuration for tracking a specific app's screen time in a dedicated slot (1 to 4).
class ScreenTimeConfig extends Equatable {
  const ScreenTimeConfig({
    this.slot = 1,
    required this.packageName,
    required this.appName,
    this.openAppOnTap = true,
  });

  final int slot;
  final String packageName;
  final String appName;
  final bool openAppOnTap;

  ScreenTimeConfig copyWith({
    int? slot,
    String? packageName,
    String? appName,
    bool? openAppOnTap,
  }) {
    return ScreenTimeConfig(
      slot: slot ?? this.slot,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      openAppOnTap: openAppOnTap ?? this.openAppOnTap,
    );
  }

  Map<String, dynamic> toMap() => {
        'slot': slot,
        'packageName': packageName,
        'appName': appName,
        'openAppOnTap': openAppOnTap,
      };

  String toJson() => jsonEncode(toMap());

  factory ScreenTimeConfig.fromMap(Map<String, dynamic> map) {
    return ScreenTimeConfig(
      slot: (map['slot'] as num?)?.toInt() ?? 1,
      packageName: (map['packageName'] as String?) ?? '',
      appName: (map['appName'] as String?) ?? '',
      openAppOnTap: (map['openAppOnTap'] as bool?) ?? true,
    );
  }

  factory ScreenTimeConfig.fromJson(String source) =>
      ScreenTimeConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [slot, packageName, appName, openAppOnTap];
}
