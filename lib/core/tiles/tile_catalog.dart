import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A Quick Settings tile. [id] must match `TileRegistry` in Kotlin.
class TileDefinition {
  const TileDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
}

const privateDnsTile = TileDefinition(
  id: 'private_dns',
  name: 'Private DNS',
  description: 'Cycle between encrypted DNS providers.',
  icon: Symbols.dns_rounded,
);

const killSwitchTile = TileDefinition(
  id: 'kill_switch',
  name: 'Internet kill switch',
  description: 'Block all traffic instantly.',
  icon: Symbols.public_off_rounded,
);

const wirelessDebuggingTile = TileDefinition(
  id: 'wireless_debugging',
  name: 'Wireless debugging',
  description: 'ADB over Wi-Fi in one tap.',
  icon: Symbols.developer_mode_rounded,
);

const grayscaleTile = TileDefinition(
  id: 'grayscale',
  name: 'Grayscale',
  description: 'A monochrome screen to cut distraction.',
  icon: Symbols.contrast_rounded,
);

const animationSpeedTile = TileDefinition(
  id: 'animation_speed',
  name: 'Animation speed',
  description: 'Cycle through animation speeds.',
  icon: Symbols.speed_rounded,
);

const quickTextsTile = TileDefinition(
  id: 'quick_texts',
  name: 'Quick texts',
  description: 'Copy saved snippets from anywhere.',
  icon: Symbols.content_paste_rounded,
);

const profilesTile = TileDefinition(
  id: 'profiles',
  name: 'Profiles',
  description: 'Apply a bundle of settings at once.',
  icon: Symbols.tune_rounded,
);

const bsDateTile = TileDefinition(
  id: 'bs_date',
  name: 'Nepali date',
  description: "Today's Bikram Sambat date at a glance.",
  icon: Symbols.calendar_month_rounded,
);

const batteryTile = TileDefinition(
  id: 'battery',
  name: 'Battery',
  description: 'Temperature and charging speed at a glance.',
  icon: Symbols.battery_charging_full_rounded,
);

const fontSizeTile = TileDefinition(
  id: 'font_size',
  name: 'Font size',
  description: 'Make text bigger in one tap.',
  icon: Symbols.format_size_rounded,
);

const caffeineTile = TileDefinition(
  id: 'caffeine',
  name: 'Caffeine',
  description: 'Keep the screen awake for a while.',
  icon: Symbols.coffee_rounded,
);

const qrScannerTile = TileDefinition(
  id: 'qr_scanner',
  name: 'Scan QR',
  description: 'Scan any QR code. Links open only when you choose.',
  icon: Symbols.qr_code_scanner_rounded,
);

const paymentQrTile = TileDefinition(
  id: 'payment_qr',
  name: 'Payment QR',
  description: 'Show your QR to get paid, even from the lock screen.',
  icon: Symbols.qr_code_2_rounded,
);

const appScreenTimeTile = TileDefinition(
  id: 'app_screen_time',
  name: 'Screen time 1',
  description: "Track today's screen time of a specific app in Quick Settings.",
  icon: Symbols.timer_rounded,
);

const appScreenTimeTile1 = appScreenTimeTile;

const appScreenTimeTile2 = TileDefinition(
  id: 'app_screen_time_2',
  name: 'Screen time 2',
  description: "Track today's screen time of a second app in Quick Settings.",
  icon: Symbols.timer_rounded,
);

const appScreenTimeTile3 = TileDefinition(
  id: 'app_screen_time_3',
  name: 'Screen time 3',
  description: "Track today's screen time of a third app in Quick Settings.",
  icon: Symbols.timer_rounded,
);

const appScreenTimeTile4 = TileDefinition(
  id: 'app_screen_time_4',
  name: 'Screen time 4',
  description: "Track today's screen time of a fourth app in Quick Settings.",
  icon: Symbols.timer_rounded,
);

TileDefinition appScreenTimeTileForSlot(int slot) {
  return switch (slot) {
    2 => appScreenTimeTile2,
    3 => appScreenTimeTile3,
    4 => appScreenTimeTile4,
    _ => appScreenTimeTile,
  };
}
