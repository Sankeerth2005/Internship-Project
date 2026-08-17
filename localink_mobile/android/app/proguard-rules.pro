# Flutter / Play Core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign-In / Play services (release minify)
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-dontwarn com.google.android.gms.**

# Keep Gson/json reflective models if used by plugins
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# OkHttp / Dio
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Flutter references Play Core deferred components APIs that are not on the classpath.
# Safe to ignore when the app does not use deferred/Play Feature Delivery components.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
