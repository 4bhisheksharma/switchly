import 'package:equatable/equatable.dart';

/// Representation of an audio input device connected to the phone.
class MicDeviceItem extends Equatable {
  const MicDeviceItem({
    required this.id,
    required this.mode,
    required this.name,
    required this.type,
    required this.isConnected,
    required this.isActive,
  });

  final String id;
  final String mode; // 'phone', 'earbuds', 'earphones'
  final String name;
  final String type; // 'builtin', 'bluetooth', 'wired'
  final bool isConnected;
  final bool isActive;

  factory MicDeviceItem.fromMap(Map<String, dynamic> map) {
    return MicDeviceItem(
      id: map['id'] as String? ?? '',
      mode: map['mode'] as String? ?? 'auto',
      name: map['name'] as String? ?? 'Microphone',
      type: map['type'] as String? ?? 'builtin',
      isConnected: map['isConnected'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, mode, name, type, isConnected, isActive];
}

/// Snapshot of the phone's microphone switcher state.
class MicState extends Equatable {
  const MicState({
    this.currentMode = 'auto',
    this.availableModes = const ['auto', 'phone'],
    this.devices = const [],
    this.isTesting = false,
    this.testLevel = 0.0,
    this.isLoading = false,
  });

  final String currentMode; // 'auto', 'phone', 'earbuds', 'earphones'
  final List<String> availableModes;
  final List<MicDeviceItem> devices;
  final bool isTesting;
  final double testLevel; // 0.0 to 1.0 live amplitude
  final bool isLoading;

  bool get isPhoneSelected => currentMode == 'phone';
  bool get isEarbudsSelected => currentMode == 'earbuds';
  bool get isEarphonesSelected => currentMode == 'earphones';
  bool get isAutoSelected => currentMode == 'auto';
  bool get isManualOverride => currentMode != 'auto';

  String get currentModeTitle => switch (currentMode) {
        'phone' => 'Phone Microphone',
        'earbuds' => 'Earbuds (Bluetooth)',
        'earphones' => 'Wired Earphones',
        _ => 'Auto (System Default)',
      };

  String get currentModeSubtitle => switch (currentMode) {
        'phone' => 'Phone built-in mic forced for calls and voice apps.',
        'earbuds' => 'Bluetooth headset mic active.',
        'earphones' => 'Wired or USB headset mic active.',
        _ => 'Android manages routing automatically based on connection.',
      };

  MicState copyWith({
    String? currentMode,
    List<String>? availableModes,
    List<MicDeviceItem>? devices,
    bool? isTesting,
    double? testLevel,
    bool? isLoading,
  }) {
    return MicState(
      currentMode: currentMode ?? this.currentMode,
      availableModes: availableModes ?? this.availableModes,
      devices: devices ?? this.devices,
      isTesting: isTesting ?? this.isTesting,
      testLevel: testLevel ?? this.testLevel,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        currentMode,
        availableModes,
        devices,
        isTesting,
        testLevel,
        isLoading,
      ];
}
