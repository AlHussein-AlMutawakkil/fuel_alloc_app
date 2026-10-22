# ProGuard rules for fuel_alloc_app
# Prevent shrinking/obfuscation from stripping Google Play Services and Google Drive APIs in release APK
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep interface com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep interface com.google.android.gms.common.** { *; }
-keep class com.google.api.services.drive.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.api.client.**
-dontwarn com.google.api.services.drive.**

-keepclassmembers class * {
    @com.google.api.client.util.Key <fields>;
}

# WorkManager background workers
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }

# SQLite and native libraries
-keep class com.tekartik.sqflite.** { *; }
