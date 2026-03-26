plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.velox.app"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.velox.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Keys are read from environment variables or local.properties for CI/CD.
            // Set VELOX_KEY_PATH, VELOX_KEY_ALIAS, VELOX_KEY_PASSWORD, VELOX_STORE_PASSWORD
            // in your environment before building a release.
            val keyPath = System.getenv("VELOX_KEY_PATH")
                ?: project.findProperty("VELOX_KEY_PATH") as String?
            val keyAlias = System.getenv("VELOX_KEY_ALIAS")
                ?: project.findProperty("VELOX_KEY_ALIAS") as String?
            val keyPassword = System.getenv("VELOX_KEY_PASSWORD")
                ?: project.findProperty("VELOX_KEY_PASSWORD") as String?
            val storePassword = System.getenv("VELOX_STORE_PASSWORD")
                ?: project.findProperty("VELOX_STORE_PASSWORD") as String?

            if (keyPath != null) {
                storeFile = file(keyPath)
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
                this.storePassword = storePassword
            } else {
                // Fall back to debug keystore if no release key is configured.
                // REPLACE THIS with a proper release keystore before publishing.
                initWith(signingConfigs.getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
