# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }

# General
-dontwarn io.flutter.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
