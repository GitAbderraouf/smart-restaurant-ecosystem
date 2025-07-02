buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.0") // Or your current Android Gradle Plugin version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // Or your current Kotlin plugin version
        classpath("com.google.gms:google-services:4.4.1") // Added Google Services classpath
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials {
                username = "mapbox"
                password = providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").getOrElse(
                    System.getenv("MAPBOX_DOWNLOADS_TOKEN") ?: ""
                )
            }
            content {
                includeModule("com.mapbox.maps", "android-sdk")
                includeModule("com.mapbox.mapboxsdk", "mapbox-android-sdk")
                includeModule("com.mapbox.mapboxsdk", "mapbox-android-gestures")
                includeModule("com.mapbox.mapboxsdk", "mapbox-android-accounts")
                includeModule("com.mapbox.mapboxsdk", "mapbox-android-telemetry")
                includeModule("com.mapbox.mapboxsdk", "mapbox-android-core")
                includeModule("com.mapbox.mapboxsdk", "mapbox-android-plugin-annotation-v9")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    project.evaluationDependsOn(":app")

    if (project.name == "mapbox_gl") {
        project.afterEvaluate {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                namespace = "com.mapbox.mapboxgl.flutter"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}