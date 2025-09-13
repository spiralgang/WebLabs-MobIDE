#!/usr/bin/env bash
# generate_apk.sh
# Scaffolds an Android application with JNI (C++), CMake integration, and optional bulk source generation.
# Safety: generation >5000 files requires CONFIRM_GENERATE=yes to proceed.
# Usage:
#   ./generate_apk.sh --name MyApp --package com.example.myapp --count 20000 --out ./generated
# Environment:
#   CONFIRM_GENERATE=yes required for count > 5000
#   SKIP_BUILD=1 to skip attempting local ./gradlew assembleDebug
set -euo pipefail

# defaults
APP_NAME="MyApp"
PKG="com.example.myapp"
COUNT=0
OUTDIR="${PWD}/generated-android"
SKIP_BUILD="${SKIP_BUILD:-0}"
PARALLEL_SHARDS=8   # distribute generation to speed IO

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) APP_NAME="$2"; shift 2;;
    --package) PKG="$2"; shift 2;;
    --count) COUNT="$2"; shift 2;;
    --out) OUTDIR="$2"; shift 2;;
    --skip-build) SKIP_BUILD=1; shift;;
    --shards) PARALLEL_SHARDS="$2"; shift 2;;
    --help) sed -n '1,160p' "$0"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

# safety guard
if [[ "${COUNT:-0}" -gt 5000 && "${CONFIRM_GENERATE:-}" != "yes" ]]; then
  echo "Requested generation count ${COUNT} exceeds 5000. To proceed, set CONFIRM_GENERATE=yes in env."
  exit 1
fi

echo "Scaffolding Android project '${APP_NAME}' (package=${PKG}) -> ${OUTDIR}, generating ${COUNT} extra files (shards=${PARALLEL_SHARDS})"
rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

# write root builds
cat > settings.gradle <<'EOF'
rootProject.name = "generated-app"
include ':app'
EOF

cat > build.gradle <<'EOF'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath("com.android.tools.build:gradle:8.1.0") }
}
allprojects {
    repositories { google(); mavenCentral() }
}
EOF

cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx3072m
android.useAndroidX=true
org.gradle.parallel=true
EOF

# app layout
mkdir -p app/src/main/{java,cpp,res/layout,res/values}
PKG_DIR=$(echo "$PKG" | tr '.' '/')
mkdir -p "app/src/main/java/${PKG_DIR}"

# app build.gradle (minimal, uses CMake)
cat > app/build.gradle <<'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android' apply false
}

android {
    compileSdk 33

    defaultConfig {
        applicationId "REPLACE_PKG"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
        externalNativeBuild {
            cmake {
                cppFlags "-std=c++17 -O2"
            }
        }
    }

    buildTypes {
        debug { ndk { debugSymbolLevel 'FULL' } }
        release { minifyEnabled false }
    }

    externalNativeBuild {
        cmake {
            path "CMakeLists.txt"
            version "3.22.1"
        }
    }

    sourceSets {
        main {
            manifest.srcFile 'src/main/AndroidManifest.xml'
            java.srcDirs = ['src/main/java']
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.9.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
EOF
# replace package placeholder
sed -i "s|REPLACE_PKG|${PKG}|g" app/build.gradle

# AndroidManifest
cat > app/src/main/AndroidManifest.xml <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="REPLACE_PKG">
    <application android:allowBackup="true" android:label="@string/app_name" android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
sed -i "s|REPLACE_PKG|${PKG}|g" app/src/main/AndroidManifest.xml

# resources
cat > app/src/main/res/values/strings.xml <<'EOF'
<resources>
    <string name="app_name">APP_NAME_PLACEHOLDER</string>
</resources>
EOF
sed -i "s|APP_NAME_PLACEHOLDER|${APP_NAME}|g" app/src/main/res/values/strings.xml

cat > app/src/main/res/layout/activity_main.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent">
    <TextView android:id="@+id/nativeText" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Native:"/>
</FrameLayout>
EOF

# MainActivity (Kotlin)
cat > "app/src/main/java/${PKG_DIR}/MainActivity.kt" <<'EOF'
package REPLACE_PKG

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    external fun stringFromJNI(): String

    init { System.loadLibrary("native-lib") }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val tv: TextView? = findViewById(R.id.nativeText)
        tv?.text = try { "Native: " + stringFromJNI() } catch (e: Throwable) { "Native: failed" }
    }
}
EOF
sed -i "s|REPLACE_PKG|${PKG}|g" "app/src/main/java/${PKG_DIR}/MainActivity.kt"

# CMake and native stub
cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.10.2)
project("generatedapp")
add_library(native-lib SHARED app/src/main/cpp/native-lib.cpp)
find_library(log-lib log)
target_link_libraries(native-lib ${log-lib})
EOF

# primary native-lib.cpp with correct JNI signature generation helper
JNI_PREFIX=$(echo "${PKG}" | sed 's/\./_/g')
cat > app/src/main/cpp/native-lib.cpp <<EOF
#include <jni.h>
#include <string>

extern "C"
JNIEXPORT jstring JNICALL
Java_${JNI_PREFIX}_MainActivity_stringFromJNI(JNIEnv* env, jobject /* this */) {
    std::string hello = "Hello from native C++";
    return env->NewStringUTF(hello.c_str());
}
EOF

# optional mass generation (sharded for speed)
if [[ "${COUNT}" -gt 0 ]]; then
  echo "Generating ${COUNT} Java classes (shards=${PARALLEL_SHARDS})..."
  GEN_DIR="app/src/main/java/${PKG_DIR}/generated"
  mkdir -p "${GEN_DIR}"
  # produce per-shard files in parallel using background jobs
  per_shard=$(( (COUNT + PARALLEL_SHARDS - 1) / PARALLEL_SHARDS ))
  shard=0
  while [[ $shard -lt "${PARALLEL_SHARDS}" ]]; do
    start=$(( shard * per_shard + 1 ))
    end=$(( (shard+1) * per_shard ))
    if [[ $start -gt ${COUNT} ]]; then break; fi
    if [[ $end -gt ${COUNT} ]]; then end=${COUNT}; fi
    (
      for i in $(seq ${start} ${end}); do
        class="GenClass${i}"
        cat > "${GEN_DIR}/${class}.java" <<JEOF
package ${PKG}.generated;
public class ${class} {
    public static String id() { return "${class}"; }
}
JEOF
      done
    ) &
    shard=$((shard+1))
  done
  wait
  echo "Generated ${COUNT} Java classes."
fi

# .gitignore
cat > .gitignore <<'EOF'
.gradle
/local.properties
/.idea
/build
app/build
*.iml
.gradle*
EOF

# README
cat > README.md <<EOF
Generated Android project with JNI scaffolding.
Usage:
  export CONFIRM_GENERATE=yes   # if generating large numbers of files
  ./generate_apk.sh --name MyApp --package com.example.myapp --count 20000
To build:
  ./gradlew assembleDebug
Notes:
- Requires Android SDK/NDK for native builds.
- For very large builds use a self-hosted runner with sufficient RAM/cores.
EOF

# create Gradle wrapper if gradle available
if command -v gradle >/dev/null 2>&1; then
  echo "Creating Gradle wrapper..."
  gradle wrapper --gradle-version 8.0 || true
else
  echo "Gradle CLI not found; ensure a gradle wrapper exists or run 'gradle wrapper' locally."
fi

# attempt build if requested
if [[ "${SKIP_BUILD}" != "1" ]]; then
  if [[ -x ./gradlew ]]; then
    echo "Attempting ./gradlew assembleDebug (may fail if SDK/NDK not installed)..."
    ./gradlew assembleDebug || echo "Build failed; ensure Android SDK/NDK set up or run on self-hosted runner."
  else
    echo "No gradlew available; skip build."
  fi
else
  echo "SKIPPING build by SKIP_BUILD=1"
fi

echo "Project scaffolding complete: ${OUTDIR}"
exit 0