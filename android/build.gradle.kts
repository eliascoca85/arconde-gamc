import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Some plugins (e.g. flutter_pcm_sound) pin an old compileSdk in their own
// build.gradle while still pulling in AndroidX artifacts that require a
// newer one — AGP's AAR metadata check then fails the build. Bumping every
// library module's compileSdk here is a safe override: it only affects
// which compile-time APIs are visible, not the app's actual minSdk/targetSdk.
subprojects {
    afterEvaluate {
        extensions.findByType(LibraryExtension::class.java)?.let { android ->
            if ((android.compileSdk ?: 0) < 36) {
                android.compileSdk = 36
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
