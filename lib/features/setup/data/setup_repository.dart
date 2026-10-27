import '../../../core/platform/qs_channel.dart';

/// Permission and tile setup operations, backed by the native channel.
class SetupRepository {
  const SetupRepository(this._channel);

  final QsChannel _channel;

  Future<bool> hasWriteSecureSettings() => _channel.hasWriteSecureSettings();

  Future<DeviceInfo> getDeviceInfo() => _channel.getDeviceInfo();

  Future<AddTileResult> requestAddTile(String tileId) => _channel.requestAddTile(tileId);

  Future<bool> openDeveloperOptions() =>
      _channel.openSystemPanel(SystemPanel.developerOptions);

  Future<bool> grantWithRoot() => _channel.grantWithRoot();
}
