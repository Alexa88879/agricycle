plugins {
    kotlin("android") version "2.1.20" apply false
    id("com.android.application") version "8.7.0" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false  // Changed from 4.4.2 to 4.3.15
   
    
    
}

buildscript {
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20")
        classpath("com.android.tools.build:gradle:8.2.2")
        // You can also add the Google Services plugin here if needed
        // classpath("com.google.gms:google-services:4.3.15")
    }

    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: Move build outputs to a common directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
