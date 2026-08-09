allprojects {
    repositories {
        google()
        mavenCentral()
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

// Some Flutter plugins (e.g. wireguard_flutter_plus) still declare a low
// compileSdk (31) while their androidx dependencies require 33/34+. Bump
// every android module whose compileSdk is below 33 to the app's SDK level.
//
// Done reflectively (not via the typed AGP DSL) because plugin modules are
// built with their own AGP classloader (AGP 7.1.3 for wireguard_flutter_plus,
// AGP 8.6/9 for others); a typed `configure<LibraryExtension>` throws a
// ClassCastException across classloaders. Modules whose compileSdk is already
// >= 33 (and thus locked by AGP 8/9) are left untouched.
//
// NOTE: `evaluationDependsOn(":app")` above means some projects are already
// evaluated by the time this block runs, and Gradle forbids registering
// afterEvaluate on an evaluated project - so run inline when that happens.
fun Project.bumpCompileSdk() {
    try {
        val androidExt = extensions.findByName("android") ?: return
        val methods = androidExt.javaClass.methods

        var current: Int? = null
        for (getterName in listOf("getCompileSdk", "getCompileSdkVersion")) {
            val getter = methods.firstOrNull {
                it.name == getterName && it.parameterCount == 0
            }
            if (getter != null) {
                current = getter.invoke(androidExt) as? Int
                break
            }
        }
        if (current != null && current >= 33) return

        val setter = methods.firstOrNull {
            (it.name == "compileSdkVersion" || it.name == "setCompileSdk") &&
                it.parameterCount == 1
        }
        if (setter == null) {
            logger.warn("NetKeep: no compileSdk setter found on ${project.name}")
            return
        }
        try {
            setter.invoke(androidExt, 36)
            logger.lifecycle("NetKeep: set compileSdk=36 on ${project.name} (was ${current ?: "unset"})")
        } catch (e: Exception) {
            val cause = e.cause ?: e
            logger.warn("NetKeep: could not set compileSdk on ${project.name}: ${cause.message}")
        }
    } catch (e: Exception) {
        logger.warn("NetKeep: error overriding compileSdk on ${project.name}: ${e.message}")
    }
}

subprojects {
    if (project.state.executed) {
        bumpCompileSdk()
    } else {
        afterEvaluate {
            bumpCompileSdk()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
