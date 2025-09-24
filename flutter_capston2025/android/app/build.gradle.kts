plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase Google Services Plugin
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter Plugin
}

android {
    namespace = "com.insect.cbnu" // ✅ Firebase와 일치
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.insect.cbnu" // ✅ Firebase와 일치
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // NOTE: replace this with your real release key config for production
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
