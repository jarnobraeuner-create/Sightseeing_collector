import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sightseeing.collector"
    // Use API 36 to match the emulator (Android 16)
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    // Use Build-Tools 36.1.0 which is already installed
    buildToolsVersion = "36.1.0"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
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
        
        // Load MAPS_API_KEY from local.properties
        val mapsKey = try {
            val localPropsFile = rootProject.file("local.properties")
            if (localPropsFile.exists()) {
                val localProps = Properties()
                localProps.load(FileInputStream(localPropsFile))
                localProps.getProperty("MAPS_API_KEY", "").ifEmpty { "AIzaSyDummy_API_Key_Replace_With_Yours" }
            } else {
                "AIzaSyDummy_API_Key_Replace_With_Yours"
            }
        } catch (e: Exception) {
            "AIzaSyDummy_API_Key_Replace_With_Yours"
        }
        manifestPlaceholders["MAPS_API_KEY"] = mapsKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
