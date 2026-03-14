import java.util.Properties
import java.io.FileInputStream
  
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.ncs.cuickdevuser"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ncs.cuickdevuser"
        minSdk = 23
        targetSdk = 36
        versionCode = 99
        versionName = "1.8.6"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
               }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
            pickFirsts.add("lib/arm64-v8a/libaosl.so")
            pickFirsts.add("lib/armeabi-v7a/libaosl.so")
            pickFirsts.add("lib/x86/libaosl.so")
            pickFirsts.add("lib/x86_64/libaosl.so")

            excludes += ("**/librive_text.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
