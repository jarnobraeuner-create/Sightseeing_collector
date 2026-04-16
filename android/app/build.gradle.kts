import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sightseeing.collector"
    // Use API 36 to match the emulator (Android 16)
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    // Use Build-Tools 36.1.0 which is already installed
    buildToolsVersion = "36.1.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sightseeing.collector"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Load MAPS_API_KEY from local.properties (not checked into VCS).
    // Add a line `MAPS_API_KEY=YOUR_API_KEY` to the project's `local.properties`.
    try {
        val localPropsFile = rootProject.file("local.properties")
        if (localPropsFile.exists()) {
            val localProps = Properties()
            localProps.load(FileInputStream(localPropsFile))
            val mapsKey = localProps.getProperty("MAPS_API_KEY", "")
            if (mapsKey.isNotEmpty()) {
                defaultConfig {
                    manifestPlaceholders["MAPS_API_KEY"] = mapsKey
                }
            } else {
                // Use dummy key to allow app to start - Maps will show error but app won't crash
                defaultConfig {
                    manifestPlaceholders["MAPS_API_KEY"] = "AIzaSyDummy_API_Key_Replace_With_Yours"
                }
            }
        } else {
            // Use dummy key to allow app to start - Maps will show error but app won't crash
            defaultConfig {
                manifestPlaceholders["MAPS_API_KEY"] = "AIzaSyDummy_API_Key_Replace_With_Yours"
            }
        }
    } catch (e: Exception) {
        // If anything fails, use dummy key to allow app to start
        defaultConfig {
            manifestPlaceholders["MAPS_API_KEY"] = "AIzaSyDummy_API_Key_Replace_With_Yours"
        }
    }
}

flutter {
    source = "../.."
}
