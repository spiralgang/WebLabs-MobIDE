# WebLabs-MobIDE ProGuard Rules for ARM64 Android Production
# Add project specific ProGuard rules here.

# Keep main application components
-keep public class com.spiralgang.weblabs.MainActivity
-keep public class com.spiralgang.weblabs.WebIDEActivity 
-keep public class com.spiralgang.weblabs.AlpineInstaller
-keep public class com.spiralgang.weblabs.AiManager

# Keep all services for background operations
-keep class com.spiralgang.weblabs.services.** { *; }

# Keep AI and Alpine Linux integration classes
-keep class com.spiralgang.weblabs.ai.** { *; }
-keep class com.spiralgang.weblabs.utils.** { *; }

# WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep WebView related classes
-keep class android.webkit.** { *; }
-keep class androidx.webkit.** { *; }

# Keep native methods for Alpine Linux integration
-keepclasseswithmembernames class * {
    native <methods>;
}

# OkHttp and Retrofit for AI API calls
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep data classes and models
-keep class com.spiralgang.weblabs.**.model.** { *; }
-keep class com.spiralgang.weblabs.**.data.** { *; }

# JSON serialization
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ARM64 optimization - keep performance critical paths
-keep class com.spiralgang.weblabs.**.performance.** { *; }

# Alpine Linux and terminal emulation
-keep class com.termux.** { *; }
-dontwarn com.termux.**

# File operations and permissions
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.documentfile.** { *; }

# Remove logging in release builds for security
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Security: Obfuscate sensitive classes but keep public APIs
-keepnames class com.spiralgang.weblabs.** { 
    public <methods>; 
}

# Keep manifest components
-keep class com.spiralgang.weblabs.WeblabsMobIDEApplication { *; }

# ARM64 specific: Keep JNI interfaces if any
-keep class * extends java.lang.Object {
    native <methods>;
}

# Keep exception details for debugging (remove in production if needed)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile