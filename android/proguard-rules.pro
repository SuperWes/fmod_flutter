# FMOD Flutter Plugin - ProGuard Rules
# These rules are automatically included by any app using this plugin

# Keep FMOD plugin classes (JNI methods are called from native code)
-keep class com.midnightlaunchgames.fmod_flutter.** { *; }

# Keep FMOD Java classes if present
-keep class org.fmod.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

