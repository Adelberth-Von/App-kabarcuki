plugins { id("com.android.application") }
android {
    namespace = "id.kabar.app"
    compileSdk = 35
    defaultConfig {
        applicationId = "id.kabar.app"
        minSdk = 29
        targetSdk = 35
        versionCode = 2
        versionName = "0.2.0"
        testInstrumentationRunner = "id.kabar.app.DeviceQA"
        testApplicationId = "id.kabar.qa"
    }
    sourceSets {
        getByName("main") { manifest.srcFile("build/generated-manifest/AndroidManifest.xml"); java.srcDirs("../src"); res.srcDirs("../res") }
        getByName("androidTest") { java.srcDirs("../tests"); java.exclude("DomainTests.java") }
    }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_1_8; targetCompatibility = JavaVersion.VERSION_1_8 }
}
val prepareManifest by tasks.registering {
    val source = rootProject.file("AndroidManifest.xml")
    val target = layout.buildDirectory.file("generated-manifest/AndroidManifest.xml")
    inputs.file(source)
    outputs.file(target)
    doLast {
        target.get().asFile.apply { parentFile.mkdirs(); writeText(source.readText().replace(" package=\"id.kabar.app\"", "")) }
    }
}
tasks.named("preBuild") { dependsOn(prepareManifest) }
