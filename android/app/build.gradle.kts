import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = file(
    providers.environmentVariable("COOKBOOK_SIGNING_PROPERTIES").orNull
        ?: "${System.getProperty("user.home")}/.config/cookbook/key.properties"
)
val signingProperties = Properties().apply {
    if (signingPropertiesFile.isFile) {
        signingPropertiesFile.inputStream().use { load(it) }
    }
}
val requiredSigningProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningProperties = requiredSigningProperties.filter {
    signingProperties.getProperty(it).isNullOrBlank()
}
val uploadKeystorePath = signingProperties.getProperty("storeFile")

val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    doLast {
        check(missingSigningProperties.isEmpty()) {
            "Release signing is not configured. Set ${missingSigningProperties.joinToString()} " +
                "in ~/.config/cookbook/key.properties or COOKBOOK_SIGNING_PROPERTIES. " +
                "See docs/release-setup.md."
        }
        check(uploadKeystorePath != null && File(uploadKeystorePath).isAbsolute) {
            "Release signing storeFile must be an absolute path outside the repository."
        }
        check(File(uploadKeystorePath).isFile) {
            "Release upload keystore was not found. See docs/release-setup.md."
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseSigning)
}

android {
    namespace = "com.thomaso.cookbook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.thomaso.cookbook"
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
    }

    signingConfigs {
        create("release") {
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
            storeFile = uploadKeystorePath?.let { file(it) }
            storePassword = signingProperties.getProperty("storePassword")
            storeType = "JKS"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
