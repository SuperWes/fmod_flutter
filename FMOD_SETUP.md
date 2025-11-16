# FMOD Engine Setup Guide

This guide walks you through setting up FMOD Engine for use with the fmod_flutter plugin.

## Quick Setup (Recommended)

1. Download FMOD Engine SDKs (Android, iOS, HTML5) from https://www.fmod.com/download
2. Extract them to the `engines/` directory following the structure in `engines/README.md`
3. Run the setup script:

```bash
cd packages/fmod_flutter
dart tool/setup_fmod.dart
```

That's it! The script will automatically copy all necessary files to the correct locations.

---

## Manual Setup (Alternative)

If you prefer to set things up manually, follow the platform-specific instructions below.

### Step 1: Download FMOD Engine

1. Go to https://www.fmod.com/download
2. Sign in or create a free account
3. Download **FMOD Engine** (not FMOD Studio) for your target platforms:
   - FMOD Engine for Android
   - FMOD Engine for iOS

## Step 2: Extract FMOD Files

### For Android

After downloading FMOD Engine for Android:

1. Extract the archive
2. Navigate to the `api/core/lib` directory
3. You'll find:
   - `fmod.jar` - Java bindings
   - Subdirectories with `.so` files for each architecture

### For iOS

After downloading FMOD Engine for iOS:

1. Extract the archive
2. Navigate to the `api/core/lib` directory
3. You'll find `fmod.framework`

## Step 3: Add FMOD to the Plugin

### Android Setup

1. Create libs directory:
   ```bash
   mkdir -p packages/fmod_flutter/android/libs
   ```

2. Copy `fmod.jar`:
   ```bash
   cp /path/to/fmod/api/core/lib/fmod.jar packages/fmod_flutter/android/libs/
   ```

3. In your main app, create jniLibs directories:
   ```bash
   mkdir -p android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
   ```

4. Copy native libraries:
   ```bash
   # ARM 64-bit (most common)
   cp /path/to/fmod/api/core/lib/arm64-v8a/libfmod.so android/app/src/main/jniLibs/arm64-v8a/
   
   # ARM 32-bit
   cp /path/to/fmod/api/core/lib/armeabi-v7a/libfmod.so android/app/src/main/jniLibs/armeabi-v7a/
   
   # x86 (emulators)
   cp /path/to/fmod/api/core/lib/x86/libfmod.so android/app/src/main/jniLibs/x86/
   cp /path/to/fmod/api/core/lib/x86_64/libfmod.so android/app/src/main/jniLibs/x86_64/
   ```

### iOS Setup

1. Create Frameworks directory:
   ```bash
   mkdir -p packages/fmod_flutter/ios/Frameworks
   ```

2. Copy FMOD framework:
   ```bash
   cp -R /path/to/fmod/api/core/lib/fmod.framework packages/fmod_flutter/ios/Frameworks/
   ```

3. Open your iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

4. In Xcode:
   - Select the Runner project
   - Go to "General" tab
   - Under "Frameworks, Libraries, and Embedded Content"
   - Click "+" and add `fmod.framework`
   - Set it to "Embed & Sign"

## Step 4: Verify Installation

### Android Verification

Check that files are in place:

```bash
# Plugin should have
ls packages/fmod_flutter/android/libs/fmod.jar

# Main app should have
ls android/app/src/main/jniLibs/arm64-v8a/libfmod.so
ls android/app/src/main/jniLibs/armeabi-v7a/libfmod.so
```

### iOS Verification

```bash
# Plugin should have
ls packages/fmod_flutter/ios/Frameworks/fmod.framework
```

And in Xcode, you should see `fmod.framework` listed under "Frameworks, Libraries, and Embedded Content".

## Step 5: Implement Real FMOD Calls (iOS)

The iOS implementation in `FmodManager.swift` currently has placeholder code. You'll need to:

1. Import FMOD headers at the top of the file
2. Replace placeholder print statements with actual FMOD C API calls
3. Reference the FMOD API documentation at https://www.fmod.com/docs

Example of what real implementation looks like:

```swift
import Foundation
// Import FMOD - you may need to create a bridging header

func initialize() -> Bool {
    var result: FMOD_RESULT
    
    result = FMOD_Studio_System_Create(&studioSystem, FMOD_VERSION)
    if result != FMOD_OK { return false }
    
    result = FMOD_Studio_System_GetCoreSystem(studioSystem, &coreSystem)
    if result != FMOD_OK { return false }
    
    result = FMOD_Studio_System_Initialize(studioSystem, 512, 
                                          FMOD_STUDIO_INIT_NORMAL,
                                          FMOD_INIT_NORMAL, nil)
    return result == FMOD_OK
}
```

## Troubleshooting

### Android: "Could not find fmod.jar"

Make sure `fmod.jar` is in `packages/fmod_flutter/android/libs/` and that `android/build.gradle` includes:

```gradle
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.jar'])
}
```

### iOS: "Framework not found fmod"

1. Verify `fmod.framework` is in `packages/fmod_flutter/ios/Frameworks/`
2. Check that it's properly referenced in the `.podspec` file
3. Run `pod install` in the `ios/` directory
4. Clean and rebuild in Xcode

### Android: "UnsatisfiedLinkError"

This means the native `.so` files aren't being found:

1. Verify files are in `android/app/src/main/jniLibs/[architecture]/`
2. Make sure you have libraries for all target architectures
3. Clean and rebuild: `flutter clean && flutter build apk`

## File Structure Summary

After setup, your structure should look like:

```
your_project/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── jniLibs/
│                   ├── arm64-v8a/
│                   │   └── libfmod.so
│                   ├── armeabi-v7a/
│                   │   └── libfmod.so
│                   ├── x86/
│                   │   └── libfmod.so
│                   └── x86_64/
│                       └── libfmod.so
├── ios/
│   └── (fmod.framework embedded via Xcode)
└── packages/
    └── fmod_flutter/
        ├── android/
        │   └── libs/
        │       └── fmod.jar
        └── ios/
            └── Frameworks/
                └── fmod.framework/
```

## Next Steps

Once FMOD Engine is set up:

1. Run `flutter pub get` in your main app
2. Try the example code in the README
3. Check console logs for any FMOD initialization messages
4. Test on real devices (not just emulators)

