import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val mapsApiKeyDev: String = localProperties.getProperty("MAPS_API_KEY_DEV") ?: ""
val mapsApiKeyProd: String = localProperties.getProperty("MAPS_API_KEY_PROD") ?: ""

val keyProperties = Properties()
val keyPropertiesFile = file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "tremble.dating.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

 signingConfigs {
    create("release") {
        keyAlias = keyProperties["keyAlias"] as? String ?: ""
        keyPassword = keyProperties["keyPassword"] as? String ?: ""
        storeFile = file("tremble-release.jks")
        storePassword = keyProperties["storePassword"] as? String ?: ""
    }
}


    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.pulse"
            versionCode = flutter.versionCode
            versionName = flutter.versionName
            manifestPlaceholders["MAPS_API_KEY"] = mapsApiKeyDev
        }
        create("prod") {
            dimension = "environment"
            applicationId = "tremble.dating.app"
            versionCode = flutter.versionCode
            versionName = flutter.versionName
            manifestPlaceholders["MAPS_API_KEY"] = mapsApiKeyProd
        }
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }
}

subprojects {
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("androidx.core:core-ktx:1.13.1")
}