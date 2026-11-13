# Switchly ProGuard / R8 Optimization Rules

# Flutter Engine and Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { *; }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { *; }
-keepclassmembernames class kotlinx.coroutines.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# CameraX & ZXing (Offline QR Scanner)
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**

# Switchly Native App Components (Quick Settings Tiles, App Widgets, Activities)
-keep class app.utils.switchly.tiles.** { *; }
-keep class app.utils.switchly.widgets.** { *; }
-keep class app.utils.switchly.volume.** { *; }
-keep class app.utils.switchly.scanner.** { *; }
-keep class app.utils.switchly.payments.** { *; }
-keep class app.utils.switchly.texts.** { *; }
-keep class app.utils.switchly.publicmode.** { *; }
-keep class app.utils.switchly.channel.** { *; }
-keep class app.utils.switchly.core.** { *; }
-keep class app.utils.switchly.power.** { *; }
-keep class app.utils.switchly.network.** { *; }
-keep class app.utils.switchly.display.** { *; }
-keep class app.utils.switchly.dns.** { *; }
-keep class app.utils.switchly.profiles.** { *; }
-keep class app.utils.switchly.screentime.** { *; }

# Google Play Core and In-App Update
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-dontwarn com.google.android.play.core.**


