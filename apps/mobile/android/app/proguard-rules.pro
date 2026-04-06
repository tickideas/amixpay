# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# Stripe
-keep class com.stripe.android.** { *; }

# Plaid
-keep class com.plaid.** { *; }
-keep class com.plaid.link.** { *; }

# mobile_scanner (ML Kit barcode + CameraX)
-keep class com.google.mlkit.** { *; }
-keep class androidx.camera.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**

# local_auth (biometrics)
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Retrofit / OkHttp (if used via Dart FFI or plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# AmixPAY app classes
-keep class com.amixpay.** { *; }

# Keep Kotlin metadata (required for reflection)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Gson / JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter Play Store deferred components (suppress warnings)
-dontwarn com.google.android.play.core.**
