import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * Release signing is optional and driven entirely by `android/key.properties`,
 * which is git-ignored. When the file is absent the release build falls back to
 * the debug signing config so `flutter build apk --release` still works on a
 * fresh clone; a real store signing key is required before publishing.
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    logger.warn(
        "Freedium: android/key.properties not found. " +
            "Release builds will be signed with the debug key and cannot be published."
    )
}

android {
    namespace = "com.bir.freedium"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    // F-Droid rebuilds the APK and signs it itself. Developer dependency
    // metadata is neither reproducible nor useful in that build, and it is
    // written into the APK by default on modern AGP versions.
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.bir.freedium"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // The VCS revision is not reproducible across build machines;
            // F-Droid rebuilds from a clean checkout and compares the output.
            vcsInfo {
                include = false
            }
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }

flutter { source = "../.." }
