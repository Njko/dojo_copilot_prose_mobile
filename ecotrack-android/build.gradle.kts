// ---------------------------------------------------------------------------
// EcoTrack — Root build file
// ---------------------------------------------------------------------------
// Top-level build configuration. Plugin versions that apply project-wide
// (AGP, Kotlin, Hilt, etc.) are declared here or in gradle/libs.versions.toml.
// Do not put module-specific configuration here.
// ---------------------------------------------------------------------------

plugins {
    // Android Gradle Plugin — applied to the :app module, not here
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android)      apply false
    alias(libs.plugins.kotlin.compose)      apply false
    alias(libs.plugins.hilt.android)        apply false
    alias(libs.plugins.ksp)                 apply false
    alias(libs.plugins.kover)               apply false
    alias(libs.plugins.ktlint)              apply false
}
