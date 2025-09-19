plugins {
    id("com.android.application")
    id("kotlin-android")
}

android {
    namespace = "com.spiralgang.weblabs"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.spiralgang.weblabs"
        minSdk = 29  // Android 10+ compliance for Docker environment
        targetSdk = 34
        versionCode = 2
        versionName = "2.0.0-docker"

        // ARM64/AArch64 specific configuration for Docker Ubuntu
        ndk {
            abiFilters += listOf("arm64-v8a")
        }

        // Enable vector drawables
        vectorDrawables {
            useSupportLibrary = true
        }

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        // Docker environment metadata
        buildConfigField("String", "ENVIRONMENT", "\"docker-ubuntu\"")
        buildConfigField("String", "CONTAINER_TYPE", "\"docker\"")
        buildConfigField("boolean", "DOCKER_ENABLED", "true")
        buildConfigField("String", "IDE_URL", "\"http://localhost:8080\"")
    }

    buildTypes {
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
        dataBinding = true
        buildConfig = true
    }
}

dependencies {
    // Android Support Libraries
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.webkit:webkit:1.8.0")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")

    // Material Design
    implementation("com.google.android.material:material:1.11.0")

    // Networking for AI and package downloads
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")

    // Terminal emulation for Alpine Linux shell
    // implementation("com.termux:terminal-emulator:0.118") // Commented out due to JitPack access issues
    // Using WebView-based terminal emulation instead

    // File management
    implementation("androidx.documentfile:documentfile:1.0.1")

    // Permissions
    implementation("com.karumi:dexter:6.2.3")

    // Background services for Alpine Linux
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // JSON handling
    implementation("org.json:json:20231013")

    // Apache Commons for file operations
    implementation("org.apache.commons:commons-compress:1.24.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}