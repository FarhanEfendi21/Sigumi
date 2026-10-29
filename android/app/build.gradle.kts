import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}
val releaseSigningPropertyNames = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
)
val releaseStoreFilePath = keyProperties.getProperty("storeFile")?.takeIf { it.isNotBlank() }
val releaseStoreFile = releaseStoreFilePath?.let { file(it) }
val hasReleaseSigning =
    releaseSigningPropertyNames.all { !keyProperties.getProperty(it).isNullOrBlank() } &&
        releaseStoreFile?.isFile == true

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sigumi.sigumi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sigumi.sigumi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = requireNotNull(releaseStoreFile)
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.configureEach {
    if (
        name == "assembleRelease" ||
            name == "bundleRelease" ||
            name.startsWith("packageRelease")
    ) {
        doFirst {
            if (!hasReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Create android/key.properties " +
                        "with keyAlias, keyPassword, storeFile, and storePassword, " +
                        "and make sure the keystore file exists.",
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// ═══════════════════════════════════════════════════════════════
// Resolve duplicate class conflict between:
//   - tflite_flutter  → com.google.ai.edge.litert:litert-api (new)
//   - tflite_audio    → org.tensorflow:tensorflow-lite-api (old)
// Both ship identical org.tensorflow.lite.* classes.
// Exclude the OLD artifact so litert-api wins.
// ═══════════════════════════════════════════════════════════════
configurations.all {
    exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
}
