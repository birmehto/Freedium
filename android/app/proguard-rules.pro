# R8 rules for Freedium (Flutter).
#
# The Flutter Gradle plugin already appends two files to every release build:
#   * $FLUTTER_ROOT/packages/flutter_tools/gradle/flutter_proguard_rules.pro
#   * the SDK's proguard-android-optimize.txt
# so this file only needs to cover the handful of things R8 cannot infer.
#
# IMPORTANT: do not add blanket keeps such as
#     -keep class io.flutter.** { *; }
#     -keep class io.flutter.plugins.** { *; }
# They disable shrinking, obfuscation and optimization for the entire Flutter
# embedding (600+ classes) and are the main reason Play Console reports low R8
# rates. The embedding is R8-safe: everything reached from C++/JNI or by name
# is annotated with @androidx.annotation.Keep (FlutterJNI, TextureRegistry,
# SurfaceTextureWrapper, FlutterCallbackInformation, ...), and the androidx
# annotation consumer rules already keep annotated classes.

# Reachable only through reflection. GeneratedPluginRegister does:
#     Class.forName("io.flutter.plugins.GeneratedPluginRegistrant")
#         .getDeclaredMethod("registerWith", FlutterEngine.class)
# The generated class also carries @Keep, but keep the entry point explicit so
# a change in the generator cannot silently break plugin registration.
-keep class io.flutter.plugins.GeneratedPluginRegistrant {
    public static void registerWith(io.flutter.embedding.engine.FlutterEngine);
}

# Plugins are compiled as libraries and depend on the embedding, which R8 sees
# as a program class. Keep the build quiet about that expected direction.
-dontwarn io.flutter.**
