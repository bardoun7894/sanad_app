# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging — keep FCM service classes
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }

# Google Sign-In + Play Services
-keep class com.google.android.gms.auth.** { *; }
-dontwarn com.google.android.gms.auth.**

# Google Pay
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**

# Google PlayCore (deferred components / Split installs — not used but referenced by Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Zego (video/audio call SDK)
-keep class im.zego.** { *; }
-dontwarn im.zego.**

# Agora (legacy — may still be in deps)
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Hive (uses reflection on type adapters)
-keep class * extends hive.HiveAdapter { *; }
-keep @hive.HiveType class * { *; }
-keepclassmembers class * {
    @hive.HiveField <fields>;
}

# Reflection-based packages
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature,InnerClasses,EnclosingMethod
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

# OkHttp / Retrofit (used by various plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Stripe (in case of future use; safe no-op if absent)
-dontwarn com.stripe.**

# Kotlin metadata
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** { volatile <fields>; }

# Razorpay / payment SDKs (defensive)
-dontwarn proguard.annotation.**

# General — preserve native method signatures for plugins via JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Suppress R8 missing-class warnings for embedded plugin code paths
-dontwarn java.lang.invoke.StringConcatFactory

# === Play Store crash fix (Gson TypeToken + Zego ZPNS) ===
# R8 strips generic Signature from anonymous TypeToken subclasses, causing
# "TypeToken must be created with a type argument" in Zego ZPNS FCM receiver.
# Root cause of 94.4% of v1.0.5 crashes. Refs: gson#2380, AOSP 247146909.
-keep class im.zego.zpns_flutter.internal.ZPNsConverter$* { *; }
-keep class im.zego.zpns_flutter.internal.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken { <fields>; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
