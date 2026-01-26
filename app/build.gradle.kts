// Updated build.gradle.kts for Java 17, enabled minification and resource shrinking, and removed OkHttp duplicate.
plugins {
    kotlin("jvm") version "1.5"
    id("com.android.application") version "7.2.0"
}

android {
    compileSdk = 31

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 21
        targetSdk = 31
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            shrinkResources = true
        }
    }
}
