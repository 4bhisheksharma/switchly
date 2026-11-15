# Privacy Policy for Switchly

**Effective Date:** November 13, 2026  
**Last Updated:** November 13, 2026  

Switchly ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy explains our practices regarding data collection, usage, and permissions.

---

### Summary: 100% On-Device, Zero Data Collection

- **No Data Collected:** Switchly does not collect, record, transmit, or share any personal information, telemetry, analytics, or behavioral data.
- **No Third-Party Trackers:** Switchly contains **zero** analytics SDKs, advertising SDKs, tracking libraries, or external telemetry tools.
- **No Cloud Accounts Required:** All features operate entirely offline and on-device.

---

### Sensitive Permissions and How They Are Used

Switchly uses Android system features and permissions solely to provide on-device Quick Settings utility toggles. Below is a detailed breakdown of each permission:

#### 1. VPN Service (`VpnService`)
- **Feature:** Internet Kill Switch tile.
- **Usage:** Switchly establishes a **local blackhole VPN interface** on your device to drop outgoing and incoming network packets when you tap the Kill Switch tile, allowing you to instantly sever network connectivity for selected or all apps.
- **Data Policy:** No traffic is inspected, decrypted, routed to external servers, logged, or collected. The local tunnel interface operates purely on-device as a local circuit breaker.

#### 2. Usage Access (`PACKAGE_USAGE_STATS`)
- **Feature:** Screen Time Quick Settings tiles and Public Mode app protection.
- **Usage:** Reads real-time foreground application usage statistics from Android's `UsageStatsManager` to:
  1. Display today's screen time for your chosen app directly in your Quick Settings panel.
  2. Detect when a restricted application is opened during Public Mode.
- **Data Policy:** Usage statistics are calculated strictly in memory on your device. No application history, app names, or timestamps are ever uploaded or shared.

#### 3. Display Over Other Apps (`SYSTEM_ALERT_WINDOW`)
- **Feature:** Public Mode.
- **Usage:** Used to display a temporary, on-device security lock overlay when a user attempts to launch a restricted application while Public Mode is enabled.
- **Data Policy:** The overlay is rendered locally by the Android `WindowManager`. No user input, keystrokes, or screen contents are captured or recorded.

#### 4. Do Not Disturb Access (`ACCESS_NOTIFICATION_POLICY`)
- **Feature:** Public Mode notification privacy.
- **Usage:** Used to temporarily suppress incoming notification previews and sounds when your phone is handed to someone else in Public Mode, protecting your private messages.
- **Data Policy:** No notification contents, titles, sender information, or text are ever read or logged.

#### 5. Camera (`CAMERA`)
- **Feature:** Quick Settings QR Scanner and Payment QR code reader.
- **Usage:** The camera is accessed only while the scanner viewfinder is actively open on your screen to parse QR code payloads locally using on-device computer vision.
- **Data Policy:** No pictures, frames, or video recordings are saved, stored in gallery, or transmitted over the internet.

#### 6. Foreground Services (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`)
- **Feature:** Caffeine tile (keeps screen on) and Public Mode (monitors foreground app during device handover).
- **Usage:** Required by Android to maintain a user-visible status bar notification while Caffeine or Public Mode is actively running, allowing you to stop the service at any time with a single tap.
- **Data Policy:** Foreground services do not collect or exfiltrate any data.

#### 7. Write Secure Settings (`WRITE_SECURE_SETTINGS`)
- **Feature:** Private DNS, Grayscale, Animator Duration Scale, and Network Mode tiles.
- **Usage:** An optional Android system permission granted by the user via ADB (`adb shell pm grant app.utils.switchly android.permission.WRITE_SECURE_SETTINGS`) to allow Switchly to toggle native system settings that Android does not expose to third-party apps by default.
- **Data Policy:** Used exclusively to modify specific user-requested system settings keys. No settings data is gathered or uploaded.

---

### App Updates

- **Google Play Edition:** Updates are distributed and managed exclusively via the official Google Play In-App Updates API (`in_app_update`). The Google Play build does not request `REQUEST_INSTALL_PACKAGES` and adheres strictly to Google Play's Device and Network Abuse Policy.
- **GitHub Edition:** Standalone APK releases available on GitHub check GitHub's public API for releases and allow manual sideloaded updating.

---

### Data Storage & Retention

All user preferences, custom quick text snippets, payment QR images, and tile configurations are stored locally on your device within Android's sandboxed private app storage (`SharedPreferences` and app data directory). This data is completely deleted when you clear app data or uninstall the app.

---

### Children's Privacy

Switchly does not address or target anyone under the age of 13. We do not knowingly collect or solicit personal information from children.

---

### Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in this document with an updated "Last Updated" date.

---

### Contact Us

If you have any questions or feedback about this Privacy Policy or Switchly's data practices, please contact:
- **Email:** developer@abhishek-sharma.com.np
- **GitHub:** https://github.com/4bhisheksharma/switchly
