import java.io.File
import java.io.FileInputStream
import java.time.LocalDate
import java.util.Properties
import javax.inject.Inject
import org.gradle.api.GradleException
import org.gradle.process.ExecOperations
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use(localProperties::load)
}

val flutterSdkPath = localProperties.getProperty("flutter.sdk")
    ?: System.getenv("FLUTTER_ROOT")
    ?: throw GradleException(
        "Flutter SDK path not found. Set flutter.sdk in android\\local.properties or FLUTTER_ROOT."
    )

val isWindowsHost = System.getProperty("os.name").startsWith("Windows", ignoreCase = true)
val dartExecutable = File(
    flutterSdkPath,
    if (isWindowsHost) "bin\\dart.bat" else "bin/dart",
)
val projectRootDir = rootProject.projectDir.parentFile

// Gradle 9 removed `project.exec { }`. A task that runs a process gets
// ExecOperations injected instead; this works on Gradle 8 and 9 alike
// (standard 5.3, flavors guide "Android Toolchain Baseline").
interface InjectedExecOperations {
    @get:Inject
    val execOperations: ExecOperations
}

val buildMetadataExec = objects.newInstance<InjectedExecOperations>().execOperations

val generateBuildMetadata = tasks.register("generateBuildMetadata") {
    group = "build setup"
    description = "Generates About-screen build metadata before Android builds."

    inputs.file(projectRootDir.resolve("pubspec.yaml"))
    inputs.file(projectRootDir.resolve("tool/generate_app_version.dart"))
    inputs.file(projectRootDir.resolve("tool/generate_build_date.dart"))
    inputs.property("metadataBuildDate", LocalDate.now().toString())
    outputs.file(projectRootDir.resolve("lib/core/constants/app_version.g.dart"))
    outputs.file(projectRootDir.resolve("lib/core/constants/build_date.g.dart"))

    doLast {
        if (!dartExecutable.exists()) {
            throw GradleException(
                "Could not find Dart executable at ${dartExecutable.absolutePath}. " +
                    "Check android\\local.properties flutter.sdk or FLUTTER_ROOT."
            )
        }

        buildMetadataExec.exec {
            workingDir = projectRootDir
            commandLine(dartExecutable.absolutePath, "run", "tool/generate_app_version.dart")
        }
        buildMetadataExec.exec {
            workingDir = projectRootDir
            commandLine(dartExecutable.absolutePath, "run", "tool/generate_build_date.dart")
        }
    }
}

tasks.named("preBuild") {
    dependsOn(generateBuildMetadata)
}

tasks.matching { task ->
    task.name.startsWith("compileFlutterBuild")
}.configureEach {
    dependsOn(generateBuildMetadata)
}

android {
    namespace = "in.sreerajp.imgvidgal"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "in.sreerajp.imgvidgal"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val props = Properties()
                props.load(keystorePropertiesFile.inputStream())
                keyAlias      = props.getProperty("keyAlias")
                keyPassword   = props.getProperty("keyPassword")
                val storeFilePath = props.getProperty("storeFile")
                if (storeFilePath != null) {
                    val fileInApp = file(storeFilePath)
                    val fileInRoot = rootProject.file(storeFilePath)
                    storeFile = if (fileInApp.exists()) fileInApp else fileInRoot
                }
                storePassword = props.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        debug {
            // Android uses SDK debug keystore automatically
        }
    }

    flavorDimensions += "environment"
    // The app name per flavor and language lives in src/<flavor>/res/values*/
    // strings.xml, never in resValue(...): a resValue cannot be translated, and
    // AGP 9 turns the feature off (flavors guide, guideline.md 1.8).
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        create("prod") {
            dimension = "environment"
        }
    }

    // Keep every language in the App Bundle. The language is picked inside
    // the app, so a Play install on an English phone must still carry the
    // Malayalam and Sanskrit resources (engineering standard §8.1).
    bundle {
        language {
            enableSplit = false
        }
    }
}

flutter {
    source = "../.."
}

// A prod release must never build without the release key. The check runs when
// the task graph is ready, so it fails at the start and not after a full build.
gradle.taskGraph.whenReady {
    val isProdRelease = allTasks.any { task ->
        task.name == "assembleProdRelease" || task.name == "bundleProdRelease"
    }
    if (isProdRelease) {
        val props = Properties()
        if (keystorePropertiesFile.exists()) {
            keystorePropertiesFile.inputStream().use(props::load)
        }
        val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
            .filter { props.getProperty(it).isNullOrBlank() }
        val storeFilePath = props.getProperty("storeFile")
        val storeFileFound = storeFilePath.isNullOrBlank() ||
            file(storeFilePath).exists() ||
            rootProject.file(storeFilePath).exists()
        if (missing.isNotEmpty() || !storeFileFound) {
            throw GradleException(
                "Prod release blocked: signing details are not complete. " +
                    "Check android/key.properties. Missing: $missing. " +
                    "Keystore file found: $storeFileFound. " +
                    "See docs/guidelines/flutter_build_flavors_guide.md."
            )
        }
    }
}

dependencies {
    // Barcode and QR decoding (BarcodeChannelHandler). The original ZXing
    // library: Apache-2.0, plain Java, no dependencies and no network code.
    // It replaced Google's closed-source ML Kit (G47). Never add
    // com.google.mlkit or com.google.android.gms here.
    implementation("com.google.zxing:core:3.5.3")
}

// The Kotlin JVM target. The old `kotlinOptions { }` inside `android { }` is
// deprecated and fails on AGP 9 (standard 5.3). Keep it equal to
// compileOptions above.
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}
