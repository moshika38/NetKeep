# ==========================================================================
# NetKeep — ProGuard / R8 Keep Rules for Release Build (minifyEnabled)
# Fixes WorkDatabase, Room, WorkManager, AdMob, Play Core & Flutter reflection crashes
# ==========================================================================

# --------------------------------------------------------------------------
# 1. AndroidX WorkManager & WorkDatabase (Fixes WorkDatabase creation crash)
# --------------------------------------------------------------------------
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.WorkManagerInitializer { *; }
-dontwarn androidx.work.**

# Keep ListenableWorker constructors instantiated via reflection by WorkManager
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# --------------------------------------------------------------------------
# 2. AndroidX Room Database & Generated Impl Classes
# --------------------------------------------------------------------------
-keep class androidx.room.** { *; }
-keep class androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase$Callback { *; }
-keep @androidx.room.Entity class * { *; }
-keep @androidx.room.Dao class * { *; }
-keep @androidx.room.Database class * { *; }
-keepclassmembers class * {
    @androidx.room.* <methods>;
}

# --------------------------------------------------------------------------
# 3. AndroidX SQLite Drivers (Used by WorkDatabase)
# --------------------------------------------------------------------------
-keep class androidx.sqlite.** { *; }
-keep class androidx.sqlite.db.** { *; }
-keep class androidx.sqlite.db.framework.** { *; }
-keep class * implements androidx.sqlite.db.SupportSQLiteOpenHelper$Factory { *; }
-dontwarn androidx.sqlite.**

# --------------------------------------------------------------------------
# 4. AndroidX Startup & Initializers
# --------------------------------------------------------------------------
-keep class androidx.startup.** { *; }
-keep class androidx.startup.InitializationProvider { *; }
-keep class * implements androidx.startup.Initializer { *; }
-keepclassmembers class * implements androidx.startup.Initializer {
    public <init>();
}

# --------------------------------------------------------------------------
# 5. Google Mobile Ads (AdMob) & Play Services
# --------------------------------------------------------------------------
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.ads.identifier.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.gms.internal.ads.**

# Generic Google Play Services SafeParcelable & Client rules
-keep public class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}
-keepnames class com.google.android.gms.common.api.GoogleApiClient
-keepnames class com.google.android.gms.ads.identifier.AdvertisingIdClient
-dontwarn com.google.android.gms.**

# --------------------------------------------------------------------------
# 6. Google Play Core & Deferred Components (Fixes R8 missing class error)
# --------------------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# --------------------------------------------------------------------------
# 7. Flutter Native Embedding & Plugins
# --------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.lifecycle.** { *; }

# Keep JNI native method signatures
-keepclasseswithmembernames class * {
    native <methods>;
}

# --------------------------------------------------------------------------
# 8. Attributes & Reflection Preservation
# --------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeVisibleFieldAnnotations
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
