import '../../../core/platform/qs_channel.dart';
import 'volume_models.dart';

class VolumeRepository {
  VolumeRepository({required this.channel});

  final QsChannel channel;

  Future<VolumeSnapshot> getLevels() async {
    try {
      final map = await channel.getVolumeLevels();
      if (map.isNotEmpty) {
        return VolumeSnapshot.fromMap(map);
      }
    } catch (_) {}
    return VolumeSnapshot.fallback;
  }

  Future<bool> setVolume(
    String stream,
    int level, {
    bool playSound = false,
    bool showUi = false,
  }) async {
    try {
      return await channel.setVolumeLevel(
        stream,
        level,
        playSound: playSound,
        showUi: showUi,
      );
    } catch (_) {
      return false;
    }
  }

  Future<int?> adjustVolume(String stream, {required bool increase}) async {
    try {
      return await channel.adjustVolume(stream: stream, increase: increase);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setRingerMode(RingerMode mode) async {
    try {
      return await channel.setRingerMode(mode.code);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showSystemVolume() async {
    try {
      return await channel.showSystemVolume();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSoundSettings() async {
    try {
      return await channel.openSoundSettings();
    } catch (_) {
      return false;
    }
  }
}

