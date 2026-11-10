<p align="center">
  <img src="assets/logo/logo_white.png" alt="Switchly logo" width="112" />
</p>

<h1 align="center">Switchly</h1>

<p align="center">
  One-tap Quick Settings tiles for the Android settings that do not have one.
</p>

<p align="center">
  <a href="https://github.com/4bhisheksharma/switchly/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/4bhisheksharma/switchly?label=release" /></a>
  <img alt="Android 10+" src="https://img.shields.io/badge/Android-10%2B-3DDC84" />
  <a href="LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/license-GPL--3.0-blue" /></a>
</p>

<p align="center">
  <img src="docs/screenshots/home.png" alt="Home screen" width="240" />
  &nbsp;
  <img src="docs/screenshots/quick-settings.png" alt="Switchly tiles in Quick Settings" width="240" />
  &nbsp;
  <img src="docs/screenshots/private-dns.png" alt="Private DNS screen" width="240" />
</p>

---

## What is Switchly?

Android's Quick Settings panel (the panel you pull down from the top of the screen) has tiles for Wi-Fi, Bluetooth and a few other things. Many useful settings are missing from it and are buried several screens deep in the Settings app, or inside Developer options.

Switchly adds those missing settings as Quick Settings tiles and interactive Home Screen widgets. Each tile does one job with a single tap, from any app, and many of them work from the lock screen. The Switchly app itself is where you choose how each tile behaves.

Switchly respects your privacy. It contains no analytics, no telemetry, and no advertisements. The network permission is used strictly to check GitHub releases for in-app updates upon request.

## Features

### Network

| Tile | What it does |
| --- | --- |
| **Private DNS** | Switches encrypted DNS between Off and providers such as AdGuard, Cloudflare, Google, Quad9 and Mullvad. Each tap moves to the next provider. You can add your own providers and choose the order. |
| **Internet kill switch** | Blocks all internet traffic instantly, with an optional list of apps that stay online. It works through Android's local VPN feature; traffic is dropped on the phone and never sent or inspected. |
| **Wireless debugging** | Turns ADB over Wi-Fi on or off and shows the address to connect to (`ip:port`). Requires Android 11 or newer. |

### Audio & Sound

| Tile | What it does |
| --- | --- |
| **Volume Control** | Adjust media, ring, notification, in-call, and alarm volume without pressing physical buttons. Tapping the tile opens a fast overlay slider directly from the shade; supports one-tap ringer mode toggle (Normal, Vibrate, Silent) and customizable stream shortcuts. |

### Privacy & Security

| Tile | What it does |
| --- | --- |
| **Public Mode** | PIN-protected guest lock for when handing your phone to someone else. Instantly hides sensitive Quick Settings tiles (Payment QR, Quick texts, etc.) and blocks designated private apps from opening until your PIN is entered. |

### Display

| Tile | What it does |
| --- | --- |
| **Grayscale** | Turns the screen black and white to reduce distraction. Your previous colour correction setting is restored when you turn it off. |
| **Animation speed** | Cycles the system animation speed, for example Off, 0.5x and 1x, to make the phone feel faster. |
| **Font size** | Cycles the system text size, for example 100%, 130% and 150%. Useful before handing the phone to someone who needs larger text. |

### Power

| Tile | What it does |
| --- | --- |
| **Caffeine** | Keeps the screen on while you read, follow directions or present. Each tap selects a longer duration (5, 15, 30, 60 minutes, no limit), and the next tap after the last one turns it off. It also turns off when the screen is locked, unless you change that. |
| **Battery** | Shows the battery level, temperature and live charging power in watts directly on the tile. |

### Everyday

| Tile | What it does |
| --- | --- |
| **App Screen Time** | Track daily screen time for specific apps directly from Quick Settings. Supports up to 4 dedicated tiles (`Tile 1`, `Tile 2`, `Tile 3`, `Tile 4`). Calculates usage 100% locally on-device using native Android `UsageStatsManager`, with zero battery drain and complete offline privacy. |
| **Payment QR** | Shows your saved payment QR codes (eSewa, Khalti, Fonepay, bank and others) full screen at maximum brightness, without opening any other app. Works from the lock screen. |
| **Scan QR** | Opens a QR scanner from anywhere. Links, phone numbers, email addresses and locations get an Open button, and Wi-Fi codes show the network name and password. Links are shown in full and are never opened automatically. Scanning happens entirely on the phone. |
| **Quick texts** | Saves text you type often, such as an address, account number or a standard reply. Tap the tile, pick a text, and it is copied to the clipboard. |
| **Nepali date & Patro** | Shows today's Bikram Sambat (BS) date, Tithi, and public holidays directly on the Quick Settings tile and in a native dialog with one-tap copy. The in-app calendar includes complete month grids with daily Tithis, gazetted public holiday highlights, monthly festival schedules, and AD ↔ BS date conversion. |
| **Profiles** | Applies several settings at once, for example "Focus" = AdGuard DNS + Grayscale + faster animations. A "Restore" option puts everything back as it was. |

### Home Screen Widgets

| Widget | What it does |
| --- | --- |
| **Volume & Compact Volume** | Change volume streams and toggle ringer modes directly from your home screen launcher. |
| **Payment QR** | One-tap access to your essential payment and merchant QR codes. |
| **Nepali Date & Compact Date** | Shows today's Bikram Sambat date with automatic daily rollover, live Tithi, and holiday indicators. |
| **Quick Actions** | Shortcut bar for essential Switchly functions and quick toggles. |

### Preferences & System

| Feature | What it does |
| --- | --- |
| **In-app updates** | Built-in GitHub release updater with instant offline connectivity detection, changelog viewer, and 1-tap seamless background download and APK installation. |
| **Lightweight & Optimized** | Built with full R8/ProGuard minification, resource shrinking, font icon tree-shaking, and per-ABI split APKs (`~21-25 MB`) for fast app launch and minimal storage footprint. |
| **Appearance & Theming** | Deep modern dark mode and clean light theme with harmonized Material 3 Indigo accents across sliders, steppers, and actions. |

Long-press any Switchly tile in Quick Settings to open its settings screen in the app.

## Screenshots

<p align="center">
  <img src="docs/screenshots/home-dark.png" alt="Home screen in dark theme" width="200" />
  &nbsp;
  <img src="docs/screenshots/kill-switch.png" alt="Internet kill switch" width="200" />
  &nbsp;
  <img src="docs/screenshots/caffeine.png" alt="Caffeine" width="200" />
  &nbsp;
  <img src="docs/screenshots/font-size.png" alt="Font size" width="200" />
</p>

<p align="center">
  <img src="docs/screenshots/quick-texts.png" alt="Quick texts" width="200" />
  &nbsp;
  <img src="docs/screenshots/payment-qr.png" alt="Payment QR" width="200" />
  &nbsp;
  <img src="docs/screenshots/nepali-date.png" alt="Nepali date calendar" width="200" />
  &nbsp;
  <img src="docs/screenshots/profiles.png" alt="Profiles" width="200" />
</p>

<p align="center">
  <img src="docs/screenshots/home-more.png" alt="Power and everyday tiles on the home screen" width="200" />
  &nbsp;
  <img src="docs/screenshots/animation-speed.png" alt="Animation speed" width="200" />
</p>

## Installation

### Requirements

- An Android phone running Android 10 or newer.
- For some tiles, a computer with ADB for a one-time setup (see below).

### Download

1. Open the [latest release](https://github.com/4bhisheksharma/switchly/releases/latest) on GitHub.
2. Under **Assets**, choose the `.apk` file for your device:
   - **`app-arm64-v8a-release.apk`**: Recommended for almost all modern Android phones.
   - **`app-armeabi-v7a-release.apk`**: For older 32-bit Android phones.
   - **`app-x86_64-release.apk`**: For Android emulators or ChromeOS devices.
3. Open the downloaded file on your phone and tap **Install**. If Android asks, allow your browser or file manager to install unknown apps.

**In-App Updates:** Once installed, Switchly checks for newer GitHub releases automatically (or via **Preferences > Check for Updates**). With instant connectivity verification, you can review release notes and install updates with a single tap without losing any saved data, QR codes, or settings.

## Getting started

### 1. Grant the one-time permission

Several tiles change system settings, which Android only allows after a special permission (`WRITE_SECURE_SETTINGS`) is granted once from a computer. This permission cannot be requested through a normal pop-up. It stays granted across reboots and app updates, and is only removed if you uninstall the app.

The tiles that need it are Private DNS, Wireless debugging, Grayscale, Animation speed, Font size and Profiles. All other tiles work without it.

1. On your phone, open **Settings > About phone** and tap **Build number** seven times to enable Developer options.
2. Open **Settings > System > Developer options** and turn on **USB debugging**.
3. Install [Android platform tools](https://developer.android.com/tools/releases/platform-tools) (ADB) on your computer.
4. Connect the phone with a USB cable, allow the debugging prompt on the phone, and run:

   ```sh
   adb shell pm grant app.utils.switchly android.permission.WRITE_SECURE_SETTINGS
   ```

5. Return to Switchly. It detects the permission automatically.

The command only grants permission to change settings. It does not root the phone or give the app any other access. You may turn USB debugging off again afterwards.

#### If the command fails

**`adb: more than one device/emulator`**

ADB can see more than one device, for example your phone and an emulator. Run `adb devices` to list them, then send the command to your phone by its serial number:

```sh
adb devices
adb -s <serial> shell pm grant app.utils.switchly android.permission.WRITE_SECURE_SETTINGS
```

Alternatively, use `adb -d shell ...` to target the only device connected by USB, or close the emulator.

**`SecurityException: ... has android.permission.GRANT_RUNTIME_PERMISSIONS`**

Some manufacturers block this command until an additional developer setting is enabled.

- **Xiaomi, Redmi and POCO (MIUI and HyperOS):** in **Settings > Additional settings > Developer options**, turn on **USB debugging (Security settings)**. This option requires a SIM card and a signed-in Mi account. Then **restart the phone**, or turn **USB debugging** off and on again and reconnect the cable. The setting only takes effect for a new debugging connection, so running the command again immediately after enabling it will still fail.
- **OPPO, Realme and OnePlus (ColorOS and OxygenOS):** in **Developer options**, turn on **Disable permission monitoring**, then disconnect and reconnect the cable.

Run the command again afterwards. When it succeeds, it prints nothing. On Xiaomi devices, leave **USB debugging (Security settings)** turned on; on some versions, turning it off removes the permission again.

After these changes it will be best to restart your phone once to align the changes perfectly.

**Rooted devices:** tap **Set up now** on the Switchly home screen and choose **Grant with root** instead of using a computer.

### 2. Add tiles to Quick Settings

On Android 13 and newer, tap **Add to Quick Settings** on any tile's screen in the app and confirm.

On any Android version, you can also add tiles manually:

1. Swipe down twice from the top of the screen to open Quick Settings.
2. Tap the edit (pencil) button.
3. Drag the Switchly tiles you want into the active area.

### 3. Customise

Open a tile's screen in the app (or long-press the tile) to choose what each tap does. For example, choose which DNS providers the Private DNS tile cycles through, which apps stay online during the kill switch, or which durations Caffeine offers.

## Permissions

Switchly only requests permissions that a feature actively uses.

| Permission | Why it is needed |
| --- | --- |
| `WRITE_SECURE_SETTINGS` | Change Private DNS, grayscale, animation speed, font size and wireless debugging. Granted once over ADB. |
| `MODIFY_AUDIO_SETTINGS` | Adjust volume streams and toggle ringer modes from the Volume Control tile and home screen widgets. |
| `PACKAGE_USAGE_STATS` | Calculate app screen time locally on-device for App Screen Time tiles, and identify restricted apps in Public Mode. |
| `ACCESS_NETWORK_STATE` | Read the Wi-Fi IP address shown by the Wireless debugging tile and detect connectivity before checking for updates. |
| `INTERNET` | Check GitHub releases and download updates when requested. Zero analytics, telemetry, or tracking. |
| `REQUEST_INSTALL_PACKAGES` | Allows 1-tap in-app installation of updates downloaded from GitHub releases. |
| `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE` | Keep the screen on while Caffeine is active, and monitor timeouts in Public Mode. |
| `ACCESS_NOTIFICATION_POLICY` | Mute notifications and manage Do Not Disturb while Public Mode is active. |
| `CAMERA` | Scan QR codes. Requested the first time you open the scanner, and only used while it is open. |

The kill switch uses Android's local VPN service; traffic is terminated locally on the device and never leaves your phone.

## Frequently asked questions

**A tile says "Tap to set up".**
The one-time permission has not been granted yet. Tap the tile, or follow [Grant the one-time permission](#1-grant-the-one-time-permission).

**The ADB command shows an error.**
See [If the command fails](#if-the-command-fails). On Xiaomi, Redmi, POCO, OPPO, Realme and OnePlus phones, an extra developer setting is required.

**How do I know what a small tile just did?**
Tiles show their current value in the tile name itself, for example "AdGuard" for Private DNS, "Anim 0.5x" for Animation speed or "Font 130%" for Font size. This name is visible even when a tile is shown at its small size, including in Control Center on Xiaomi phones.

**Why does the kill switch replace my VPN?**
Android allows only one VPN at a time. While the kill switch is on, any other VPN app is disconnected.

**Will my phone manufacturer's settings work?**
Switchly uses standard Android settings and is tested on stock Android (Pixel). Some manufacturers modify these settings, so individual tiles may behave differently on their devices. Please open an issue if a tile does not work on your phone.

**The battery wattage looks wrong.**
Some manufacturers report charging current in non-standard units. Switchly corrects the common cases, but values may be inaccurate on some devices.

## Building from source

Switchly is built with Flutter (user interface) and Kotlin (Quick Settings tiles, widgets, and system integration).

```sh
git clone https://github.com/4bhisheksharma/switchly.git
cd switchly
flutter pub get
flutter build apk --release --split-per-abi
```

The optimized, minified split APKs are written to `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-x86_64-release.apk` (x86_64 emulator / PC)

Use a release build when testing tile responsiveness. Debug builds are considerably slower on Android.

## Contributing

Bug reports, device compatibility reports and pull requests are welcome. Please open an issue to discuss larger changes before starting work on them.

## License

Copyright (C) 2026 Abhishek Sharma

Switchly is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Switchly is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [LICENSE](LICENSE) file for the full text.
