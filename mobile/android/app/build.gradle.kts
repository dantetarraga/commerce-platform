import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push (FCM): un solo google-services.json con las dos apps del proyecto de Firebase
// (pe.apamuy.app y pe.apamuy.socios), ignorado por git. Sin él, la app compila igual
// y simplemente no recibe push.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// La key de Google Maps vive en android/local.properties (ignorado por git).
val localProperties = Properties().apply {
    rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

// Firma de publicación: android/key.properties (ignorado por git) apunta a la llave
// de subida a Google Play. Sin ese archivo, la versión release se firma con la llave
// de pruebas: sirve para probarla en un celular, no para publicarla.
val keyProperties = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}
val hasUploadKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "pe.apamuy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications usa APIs de java.time.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // El applicationId de cada app se define en productFlavors.
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = localProperties.getProperty("MAPS_API_KEY") ?: ""
    }

    // Dos apps desde el mismo código: la del cliente y Apamuy Socios (negocio y
    // repartidor). Cada una se instala por separado. Ver docs/OPERACION.md.
    flavorDimensions += "app"
    productFlavors {
        create("customer") {
            dimension = "app"
            applicationId = "pe.apamuy.app"
            manifestPlaceholders["appName"] = "Apamuy"
        }
        create("partner") {
            dimension = "app"
            applicationId = "pe.apamuy.socios"
            manifestPlaceholders["appName"] = "Apamuy Socios"
        }
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
