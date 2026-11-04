import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

enum RingerMode {
  silent(0, 'Silent', Symbols.volume_off_rounded),
  vibrate(1, 'Vibrate', Symbols.vibration_rounded),
  normal(2, 'Sound On', Symbols.volume_up_rounded);

  const RingerMode(this.code, this.label, this.icon);
  final int code;
  final String label;
  final IconData icon;

  static RingerMode fromCode(int code) => switch (code) {
        0 => silent,
        1 => vibrate,
        _ => normal,
      };
}

class VolumeStreamState extends Equatable {
  const VolumeStreamState({
    required this.stream,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.current,
    required this.max,
    required this.min,
    required this.percent,
  });

  final String stream;
  final String label;
  final String subtitle;
  final IconData icon;
  final int current;
  final int max;
  final int min;
  final int percent;

  bool get isMuted => current <= min || percent == 0;

  VolumeStreamState copyWith({
    int? current,
    int? max,
    int? min,
    int? percent,
  }) =>
      VolumeStreamState(
        stream: stream,
        label: label,
        subtitle: subtitle,
        icon: icon,
        current: current ?? this.current,
        max: max ?? this.max,
        min: min ?? this.min,
        percent: percent ?? this.percent,
      );

  factory VolumeStreamState.fromMap(
    String stream,
    Map<dynamic, dynamic>? map, {
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final cur = (map?['current'] as num?)?.toInt() ?? 10;
    final maxVal = (map?['max'] as num?)?.toInt() ?? 15;
    final minVal = (map?['min'] as num?)?.toInt() ?? 0;
    final pct = (map?['percent'] as num?)?.toInt() ??
        (maxVal > minVal ? (((cur - minVal) / (maxVal - minVal)) * 100).toInt() : 50);

    return VolumeStreamState(
      stream: stream,
      label: label,
      subtitle: subtitle,
      icon: icon,
      current: cur,
      max: maxVal,
      min: minVal,
      percent: pct.clamp(0, 100),
    );
  }

  @override
  List<Object?> get props => [stream, label, current, max, min, percent];
}

class VolumeSnapshot extends Equatable {
  const VolumeSnapshot({
    required this.music,
    required this.ring,
    required this.notification,
    required this.alarm,
    required this.call,
    required this.ringerMode,
  });

  final VolumeStreamState music;
  final VolumeStreamState ring;
  final VolumeStreamState notification;
  final VolumeStreamState alarm;
  final VolumeStreamState call;
  final RingerMode ringerMode;

  factory VolumeSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final modeCode = (map['ringerMode'] as num?)?.toInt() ?? 2;

    Map<dynamic, dynamic>? streamMap(String key) {
      final val = map[key];
      return val is Map ? val : null;
    }

    return VolumeSnapshot(
      music: VolumeStreamState.fromMap(
        'music',
        streamMap('music'),
        label: 'Media',
        subtitle: 'Music, videos, games and podcasts',
        icon: Symbols.music_note_rounded,
      ),
      ring: VolumeStreamState.fromMap(
        'ring',
        streamMap('ring'),
        label: 'Ringtone',
        subtitle: 'Incoming phone calls',
        icon: Symbols.phone_in_talk_rounded,
      ),
      notification: VolumeStreamState.fromMap(
        'notification',
        streamMap('notification'),
        label: 'Notifications',
        subtitle: 'App alerts and messages',
        icon: Symbols.notifications_rounded,
      ),
      alarm: VolumeStreamState.fromMap(
        'alarm',
        streamMap('alarm'),
        label: 'Alarm',
        subtitle: 'Alarm clocks and timers',
        icon: Symbols.alarm_rounded,
      ),
      call: VolumeStreamState.fromMap(
        'call',
        streamMap('call'),
        label: 'Voice call',
        subtitle: 'In-call earpiece and speaker loudness',
        icon: Symbols.call_rounded,
      ),
      ringerMode: RingerMode.fromCode(modeCode),
    );
  }

  static const fallback = VolumeSnapshot(
    music: VolumeStreamState(
      stream: 'music',
      label: 'Media',
      subtitle: 'Music, videos, games and podcasts',
      icon: Symbols.music_note_rounded,
      current: 12,
      max: 15,
      min: 0,
      percent: 80,
    ),
    ring: VolumeStreamState(
      stream: 'ring',
      label: 'Ringtone',
      subtitle: 'Incoming phone calls',
      icon: Symbols.phone_in_talk_rounded,
      current: 10,
      max: 15,
      min: 0,
      percent: 66,
    ),
    notification: VolumeStreamState(
      stream: 'notification',
      label: 'Notifications',
      subtitle: 'App alerts and messages',
      icon: Symbols.notifications_rounded,
      current: 10,
      max: 15,
      min: 0,
      percent: 66,
    ),
    alarm: VolumeStreamState(
      stream: 'alarm',
      label: 'Alarm',
      subtitle: 'Alarm clocks and timers',
      icon: Symbols.alarm_rounded,
      current: 14,
      max: 15,
      min: 0,
      percent: 93,
    ),
    call: VolumeStreamState(
      stream: 'call',
      label: 'Voice call',
      subtitle: 'In-call earpiece and speaker loudness',
      icon: Symbols.call_rounded,
      current: 8,
      max: 10,
      min: 0,
      percent: 80,
    ),
    ringerMode: RingerMode.normal,
  );

  @override
  List<Object?> get props => [music, ring, notification, alarm, call, ringerMode];
}

