plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read flutter properties from gradle.properties safely
val flutterVersionCode: Int? = project.findProperty("flutter.versionCode")?.toString()?.toIntOrNull()
val flutterVersionName: String? = project.findProperty("flutter.versionName")?.toString()

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    // Ensure a compatible NDK version for plugins that require newer NDK
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // cloud_firestore requires minSdk 23 or higher
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode ?: 1
        versionName = flutterVersionName ?: "1.0.0"
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

