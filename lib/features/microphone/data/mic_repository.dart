import 'dart:async';
import '../../../core/platform/qs_channel.dart';
import 'mic_models.dart';

class MicRepository {
  const MicRepository(this._channel);

  final QsChannel _channel;

  Stream<double> get micLevels => _channel.micLevels;
  Stream<String> get micModeChanges => _channel.micModeChanges;

  Future<MicState> loadState() async {
    final raw = await _channel.getMicState();
    final devices = raw.devices.map(MicDeviceItem.fromMap).toList();
    return MicState(
      currentMode: raw.currentMode,
      availableModes: raw.availableModes,
      devices: devices,
    );
  }

  Future<bool> setMode(String mode) async {
    return await _channel.setMicMode(mode);
  }

  Future<bool> startMicTest() async {
    return await _channel.startMicTest();
  }

  Future<bool> stopMicTest() async {
    return await _channel.stopMicTest();
  }
}
