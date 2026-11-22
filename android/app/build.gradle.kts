import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.walletmelt.wallet_melt"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("local.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.walletmelt.wallet_melt"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    flavorDimensions += "default"
    productFlavors {
        create("production") {
            dimension = "default"
            applicationId = "app.walletmelt.wallet_melt"
        }
        create("screenshots") {
            dimension = "default"
            applicationId = "app.walletmelt.wallet_melt.screenshots"
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            storeFile = if (storeFilePath != null) file(storeFilePath) else null
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
        }
    }

    // Release builds fall back to the debug key when no keystore is configured
    // in android/local.properties. Say so loudly, and let release pipelines opt
    // into failing instead (-Pwalletmelt.requireReleaseSigning=true or
    // WALLETMELT_REQUIRE_RELEASE_SIGNING=true).
    val isSigningConfigured = keystoreProperties.getProperty("storeFile") != null
    val isReleaseBuild = gradle.startParameter.taskNames.any {
        it.contains("Release", ignoreCase = true)
    }
    val requireReleaseSigning =
        (project.findProperty("walletmelt.requireReleaseSigning") as String?)?.toBoolean() == true ||
            System.getenv("WALLETMELT_REQUIRE_RELEASE_SIGNING") == "true"
    if (isReleaseBuild && !isSigningConfigured) {
        val message = "WalletMelt release build is DEBUG-SIGNED: no storeFile in " +
            "android/local.properties. Debug-signed APKs cannot be upgraded in place " +
            "by a properly signed build later."
        if (requireReleaseSigning) {
            throw GradleException(message)
        }
        logger.warn("WARNING: $message")
    }

    buildTypes {
        release {
            signingConfig = if (isSigningConfigured) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
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
