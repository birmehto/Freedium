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

/**
 * AdMob application id, kept out of version control.
 *
 * Read from the repo-root `.env` — the same file `envied` reads for the Dart
 * side — so a real id is never committed. Copy `.env.example` to `.env` and set
 * `ADMOB_APP_ID`. When the file or key is missing (fresh clone, CI), Google's
 * public test id is used so builds keep working and serve test ads.
 */
val admobAppId: String = run {
    val envFile = rootProject.file("../.env")
    val envProperties = Properties()
    if (envFile.exists()) envFile.inputStream().use { envProperties.load(it) }
    envProperties.getProperty("ADMOB_APP_ID")?.takeIf { it.isNotBlank() }
        ?: "ca-app-pub-3940256099942544~3347511713"
}

android {
    namespace = "com.bir.freedium"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

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
        manifestPlaceholders["admobAppId"] = admobAppId
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
