# Flutter engine — always required
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Native sqflite plugin
-keep class com.tekartik.sqflite.** { *; }

# AndroidX and security rules
-keep class androidx.biometric.** { *; }

# Play Core — referenced by the Flutter embedding, never used by this app.
#
# The embedding ships classes for Play Store deferred components, and those
# reference Play Core. This app has no deferred components and must not add
# Play Core: it is a proprietary SDK, and hard rule 1 allows open source only.
# Nothing here is reachable at runtime, so telling R8 not to warn about the
# missing classes is the whole fix. Do not "solve" this by adding the
# dependency.
-dontwarn com.google.android.play.core.**
