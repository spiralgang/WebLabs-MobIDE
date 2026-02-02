// Root build.gradle.kts
plugins {
    id("com.android.application") version "8.2.2" apply true
    id("com.android.library") version "8.2.2" apply true
    id("org.jetbrains.kotlin.android") version "1.9.22" apply true
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
