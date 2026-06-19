# Flutter / Android Proguard Rules

# Keep Flutter embedding and plugins classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite native bindings and runtime classes
-keep class * extends androidx.room.RoomDatabase
-dontwarn com.sqlite3.**
-dontwarn org.sqlite.**
-keep class com.sqlite3.** { *; }
-keep class org.sqlite.** { *; }

# share_plus rules
-keep class dev.fluttercommunity.plus.share.** { *; }

# file_picker rules
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# flutter_image_compress rules
-keep class com.flutter_image_compress.** { *; }

# Ignore Google Play Core deferred component classes that are not used in WalletMelt
-dontwarn com.google.android.play.core.**
