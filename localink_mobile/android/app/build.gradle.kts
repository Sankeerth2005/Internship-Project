import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing / local overrides (never commit secrets)
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun secret(name: String): String? =
    System.getenv(name)
        ?: keyProps.getProperty(name)
        ?: localProps.getProperty(name)
        ?: (project.findProperty(name) as String?)

android {
    namespace = "com.vocalforsanatan.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        val storePasswordValue = secret("KEYSTORE_PASSWORD")
        val keyAliasValue = secret("KEY_ALIAS")
        val keyPasswordValue = secret("KEY_PASSWORD")

        if (!storePasswordValue.isNullOrBlank()
            && !keyAliasValue.isNullOrBlank()
            && !keyPasswordValue.isNullOrBlank()
        ) {
            create("release") {
                val storePath = secret("KEYSTORE_FILE") ?: "vocal-release.keystore"
                storeFile = file(storePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    defaultConfig {
        applicationId = "com.vocalforsanatan.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_WEB_CLIENT_ID"] =
            secret("GOOGLE_WEB_CLIENT_ID") ?: ""
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            val releaseSigning = signingConfigs.findByName("release")
            if (releaseSigning != null) {
                signingConfig = releaseSigning
            } else {
                val allowDebugFallback =
                    secret("ALLOW_DEBUG_RELEASE_SIGNING")?.equals("true", ignoreCase = true) == true
                if (!allowDebugFallback) {
                    throw GradleException(
                        "Release signing secrets missing. Set KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD " +
                            "(and KEYSTORE_FILE) in android/key.properties or env. " +
                            "For local testing only, set ALLOW_DEBUG_RELEASE_SIGNING=true."
                    )
                }
                logger.warn("WARNING: release build is signed with the debug keystore")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.annotation:annotation:1.7.0")
}

flutter {
    source = "../.."
}
