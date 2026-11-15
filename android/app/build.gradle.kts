import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val hasReleaseKeystore = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !keystoreProperties.getProperty(it).isNullOrBlank() }

android {
    namespace = "app.utils.switchly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.utils.switchly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 29 // Settings.Panel and tile subtitles need API 29.
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "version"
    productFlavors {
        create("play") {
            dimension = "version"
            isDefault = true
        }
        create("github") {
            dimension = "version"
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1"
            )
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Lets `flutter run --release` work locally. Never upload this build to Play.
                logger.warn("android/key.properties is incomplete: release build is signed with the DEBUG key.")
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    // QR scanner: CameraX for the camera, ZXing to decode. Both Apache 2.0 and fully offline
    // (ML Kit would need Google Play Services and isn't open source).
    implementation("androidx.activity:activity-ktx:1.10.1")
    implementation("androidx.camera:camera-camera2:1.4.2")
    implementation("androidx.camera:camera-lifecycle:1.4.2")
    implementation("androidx.camera:camera-view:1.4.2")
    implementation("com.google.zxing:core:3.5.3")

    // Nepali calendar patro (tithi, holidays, events)
    implementation("io.github.sanamhub:nepdate:0.1.0-beta.1")
    implementation("io.github.sanamhub:nepdate-patro:0.1.0-beta.1")
}

// Fallback so running `flutter run` without `--flavor` finds the debug APK.
tasks.configureEach {
    if (name == "assembleDebug" || name == "assemblePlayDebug") {
        doLast {
            val buildDir = layout.buildDirectory.get().asFile
            val flutterApkDir = File(buildDir, "outputs/flutter-apk")
            val playApkInFlutter = File(flutterApkDir, "app-play-debug.apk")
            val playApkInApk = File(buildDir, "outputs/apk/play/debug/app-play-debug.apk")
            val fallbackApk = File(flutterApkDir, "app-debug.apk")

            val source = when {
                playApkInFlutter.exists() -> playApkInFlutter
                playApkInApk.exists() -> playApkInApk
                else -> null
            }
            if (source != null) {
                flutterApkDir.mkdirs()
                source.copyTo(fallbackApk, overwrite = true)
            }
        }
    }
}
