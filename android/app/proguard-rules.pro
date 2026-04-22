#----------------------------------------------------------------------
# CoreSync ProGuard / R8 Rules
#----------------------------------------------------------------------

##--- Google ML Kit (text recognition + mobile_scanner barcode) ---##
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

##--- CameraX (mobile_scanner) ---##
-keep public class androidx.camera.core.** { public *; }
-keep class * implements androidx.camera.core.ImageAnalysis$Analyzer { *; }

##--- Gson (flutter_local_notifications v18) ---##
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

##--- Tink / AndroidX Security (flutter_secure_storage) ---##
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

##--- uCrop (image_cropper) ---##
-dontwarn com.yalantis.ucrop**
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

##--- App Android components (Manifest-referenced, reflection-instantiated) ---##
-keep class com.mujtaba.coresync.StepSyncWorker { *; }
-keep class com.mujtaba.coresync.StepCounterForegroundService { *; }
-keep class com.mujtaba.coresync.StepCounterBootReceiver { *; }
-keep class com.mujtaba.coresync.MainActivity { *; }