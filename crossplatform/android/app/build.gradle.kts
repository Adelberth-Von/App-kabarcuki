plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
val sharedJava = tasks.register<Sync>("syncSharedJava") {
    from("../../../src") { exclude("**/MainActivity.java") }
    into(layout.buildDirectory.dir("sharedJava"))
}
tasks.configureEach { if (name == "preBuild") dependsOn(sharedJava) }
android {
    namespace = "id.kabar.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "id.kabar.app"
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    sourceSets.getByName("main") {
        java.srcDir(layout.buildDirectory.dir("sharedJava").get().asFile)
        res.srcDir("../../../res")
    }
    signingConfigs {
        create("abc") {
            val key = System.getenv("ABC_KEYSTORE")
            if (key != null) {
                storeFile = file(key)
                storePassword = System.getenv("ABC_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ABC_KEY_ALIAS") ?: "kabar"
                keyPassword = System.getenv("ABC_KEYSTORE_PASSWORD")
            }
        }
    }
    buildTypes {
        debug {
            if (System.getenv("ABC_KEYSTORE") != null) signingConfig = signingConfigs.getByName("abc")
        }
        release {
            signingConfig = if (System.getenv("ABC_KEYSTORE") != null) signingConfigs.getByName("abc") else signingConfigs.getByName("debug")
        }
    }
}
flutter { source = "../.." }
