import java.util.Properties
import java.io.File

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

// AGP 9 + android.newDsl=false disables defaultConfig.resValue. Emit the string
// resource google_sign_in_android looks up via getIdentifier("default_web_client_id").
val googleWebClientIdForRes = secret("GOOGLE_WEB_CLIENT_ID")?.trim().orEmpty()
    .ifEmpty { "missing-web-client-id.apps.googleusercontent.com" }
val generatedGoogleSignInResDir = layout.buildDirectory.get()
    .dir("generated/google_sign_in/res")
    .asFile
run {
    val valuesDir = File(generatedGoogleSignInResDir, "values")
    valuesDir.mkdirs()
    // Client IDs are [A-Za-z0-9._-] — safe for XML text.
    File(valuesDir, "google_sign_in.xml").writeText(
        """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <string name="default_web_client_id" translatable="false">$googleWebClientIdForRes</string>
        </resources>
        """.trimIndent() + "\n"
    )
}

android {
    namespace = "com.vocalforsanatan.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            // Pass a File (not a Provider) so AGP 9 accepts the generated res dir.
            res.srcDir(generatedGoogleSignInResDir)
        }
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
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            val googleWebClientId = secret("GOOGLE_WEB_CLIENT_ID")?.trim().orEmpty()
            if (googleWebClientId.isEmpty()) {
                throw GradleException(
                    "Release builds require GOOGLE_WEB_CLIENT_ID (Web OAuth client). " +
                        "Set it in the repo-root .env / android/local.properties / env, " +
                        "then rebuild with scripts/build_from_env.ps1 or build_play_aab.ps1."
                )
            }
            val googleAndroidClientId = secret("GOOGLE_ANDROID_CLIENT_ID")?.trim().orEmpty()
            if (googleAndroidClientId.isNotEmpty() &&
                googleAndroidClientId.equals(googleWebClientId, ignoreCase = true)
            ) {
                throw GradleException(
                    "GOOGLE_WEB_CLIENT_ID must be the Web OAuth client, not GOOGLE_ANDROID_CLIENT_ID. " +
                        "Android clients are matched by package + SHA-1; only the Web client is used as serverClientId."
                )
            }

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
