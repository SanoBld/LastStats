// CI helper (Kotlin DSL). Applied from android/build.gradle.kts.
// Usage: ./gradlew collectApk -PapkSrc=app-release.apk -PapkName=app-universal-release.apk
// Copies the APK built by "flutter build apk" into dist/ with the final name.
tasks.register<Copy>("collectApk") {
    val src = providers.gradleProperty("apkSrc")
    val name = providers.gradleProperty("apkName")
    from(rootDir.resolve("../build/app/outputs/flutter-apk")) {
        include(src.get())
        rename { name.get() }
    }
    into(rootDir.resolve("../dist"))
}
