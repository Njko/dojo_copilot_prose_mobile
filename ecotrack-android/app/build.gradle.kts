plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt.android)
    alias(libs.plugins.ksp)
    alias(libs.plugins.kover)
    alias(libs.plugins.ktlint)
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
    // JUnit5 support for Android unit tests (JVM layer — no emulator required)
    id("de.mannodermaus.android-junit5") version "1.10.0.0"
}

android {
    namespace = "com.ecotrack"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.ecotrack"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable Java 8+ API desugaring for LocalDate on API < 26
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true  // Required for Robolectric
            all { test ->
                // Enable JUnit Platform so Gradle discovers JUnit5 tests
                test.useJUnitPlatform()
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Kover — code coverage configuration
// ---------------------------------------------------------------------------
kover {
    reports {
        filters {
            excludes {
                // Exclude generated Hilt and DI code from coverage
                classes("*_HiltModules*", "*Hilt_*", "dagger.*", "hilt_aggregated_deps.*")
                // Exclude DI modules themselves (no logic to test)
                packages("com.ecotrack.di")
                // Exclude Compose previews
                annotatedBy("androidx.compose.ui.tooling.preview.Preview")
            }
        }
        verify {
            rule("Domain layer coverage") {
                minBound(80)
                filters {
                    includes {
                        packages("com.ecotrack.domain")
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Dependencies
// ---------------------------------------------------------------------------
dependencies {
    // Desugaring for java.time on older APIs
    coreLibraryDesugaring(libs.android.desugar)

    // Compose BOM — pins all Compose library versions
    val composeBom = platform(libs.compose.bom)
    implementation(composeBom)
    androidTestImplementation(composeBom)

    // Core Android
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)

    // Compose UI
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.graphics)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.material3)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    // Navigation
    implementation(libs.androidx.navigation.compose)

    // Hilt — dependency injection
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    // Room — local database
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    // DataStore — encrypted preferences
    implementation(libs.datastore.preferences)
    implementation(libs.security.crypto)

    // WorkManager — background sync
    implementation(libs.work.runtime.ktx)
    implementation(libs.hilt.work)
    ksp(libs.hilt.work.compiler)

    // Firebase
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.crashlytics)
    implementation(libs.firebase.analytics)
    implementation(libs.firebase.perf)

    // Logging
    implementation(libs.timber)

    // Coroutines
    implementation(libs.kotlinx.coroutines.android)

    // ---------------------------------------------------------------------------
    // Test dependencies
    // ---------------------------------------------------------------------------

    // Unit tests — JUnit4 (kept for HabitTest and LogHabitCompletionUseCaseTest)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.mockito.kotlin)
    testImplementation(libs.turbine)  // Flow testing

    // ---------------------------------------------------------------------------
    // JUnit5 — required by CarbonCalculatorTest (Phase 4 PROSE Dojo)
    // ---------------------------------------------------------------------------
    // JUnit5 is NOT bundled with Android Studio by default.
    // These three lines are the minimum required to run @Test / @DisplayName
    // tests that use org.junit.jupiter.* APIs.
    //
    // Plugin: de.mannodermaus.android-junit5 (declared in the plugins block above)
    // bridges the Android Gradle Plugin with the JUnit Platform.
    // See docs/junit5-setup.md for a full explanation.
    // ---------------------------------------------------------------------------
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.10.1")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.10.1")
    // AssertJ — fluent assertions library (optional, enriches assertion readability)
    testImplementation("org.assertj:assertj-core:3.24.2")

    // Instrumented tests
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.espresso.core)
    androidTestImplementation(libs.compose.ui.test.junit4)
    androidTestImplementation(libs.hilt.android.testing)
    kspAndroidTest(libs.hilt.compiler)
}
