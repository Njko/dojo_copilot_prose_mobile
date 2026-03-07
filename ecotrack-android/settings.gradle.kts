// ---------------------------------------------------------------------------
// EcoTrack — Gradle settings
// ---------------------------------------------------------------------------
// This file declares the project name and included modules.
// It also configures the plugin and dependency repositories so that Gradle
// knows where to download the android-junit5 plugin and all other artifacts.
// ---------------------------------------------------------------------------

pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        // Required for the de.mannodermaus.android-junit5 plugin
        maven { url = uri("https://plugins.gradle.org/m2/") }
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "EcoTrack"
include(":app")
