# fmod_flutter

A Flutter plugin for FMOD Studio audio engine integration. Add professional game audio to your Flutter apps with FMOD's powerful features including 3D audio, real-time parameters, and adaptive music.

## Features

- ✅ Play FMOD Studio events (music, sound effects, ambient audio)
- ✅ Real-time parameter control
- ✅ Pause/resume/stop events
- ✅ Volume control per event
- ✅ Multiple bank loading
- ✅ Cross-platform:
  - **iOS**: Full native integration (device & simulator)
  - **Android**: Full native integration
  - **Web**: Experimental WebAssembly support

---

## Quick Start: Run the Example App

The example app includes audio banks, but you need to set up FMOD Engine native libraries first.

### 1. Clone Repository

```bash
git clone https://github.com/SuperWes/fmod_flutter.git
cd fmod_flutter
```

**What you have now:**
- ✅ Example app code and audio banks
- ❌ FMOD Engine native libraries (required to run)

### 2. Download FMOD Engine

FMOD Engine files are proprietary and not included in this repo. Each developer must download them:

1. Create free account at [fmod.com/download](https://www.fmod.com/download)
2. Download **FMOD Studio API** (NOT FMOD Studio) for your platform:
   - iOS: `fmodstudioapi*ios-installer.dmg`
   - Android: `fmodstudioapi*android.tar.gz`
   - Web: `fmodstudioapi*html5.zip`

### 3. Run Setup Script

**Important**: Run these commands from the plugin root (`fmod_flutter/`), NOT from the example directory.

```bash
# Make sure you're in the plugin root directory
# pwd should show: .../fmod_flutter

# Create engines directory
mkdir engines

# Move your downloaded FMOD files to engines/
# engines/fmodstudioapi*ios-installer.dmg
# engines/fmodstudioapi*android.tar.gz
# engines/fmodstudioapi*html5.zip

# Run setup (extracts SDKs and copies native libraries)
dart tool/setup_fmod.dart
```

**What this does:**
- Extracts FMOD SDKs
- Copies iOS libraries to `ios/FMOD/`
- Copies Android libraries to `example/android/app/src/main/jniLibs/`
- Copies Web files to `example/web/fmod/`

### 4. Run Example

**Now** you can move to the example directory and run the app:

```bash
cd example
flutter run
```

The example app demonstrates:
- FMOD initialization
- Loading banks
- Playing music and sound effects
- Parameter control
- Event management

---

## Add to Your Own Project

### Step 1: Add Plugin

```yaml
# pubspec.yaml
dependencies:
  fmod_flutter:
    git:
      url: https://github.com/SuperWes/fmod_flutter.git
  # Or when published: fmod_flutter: ^0.1.0
```

```bash
flutter pub get
```

### Step 2: Set Up FMOD

```bash
# In your project root
mkdir engines

# Download FMOD Studio API from fmod.com
# Place downloaded files in engines/

# Run setup script
dart run fmod_flutter:setup_fmod
```

The script will:
- Extract SDK archives
- Copy native libraries to `android/app/src/main/jniLibs/`
- Copy iOS libraries to `ios/FMOD/`
- Copy web files to `web/fmod/`

### Step 3: Add Your Audio Banks

#### Option A: Use Sample Banks (Quick Test)

Copy example banks from this plugin:

```bash
mkdir -p assets/audio
cp path/to/fmod_flutter/example/assets/audio/*.bank assets/audio/
```

#### Option B: Create Your Own (Recommended)

1. Download FMOD Studio from [fmod.com/download](https://www.fmod.com/download)
2. Create your audio project
3. Build banks: `File → Build`
4. Copy `.bank` files to `assets/audio/`

#### Update pubspec.yaml:

```yaml
flutter:
  assets:
    - assets/audio/Master.bank
    - assets/audio/Master.strings.bank
    - assets/audio/Music.bank
    - assets/audio/SFX.bank
```

### Step 4: Initialize FMOD

```dart
import 'package:fmod_flutter/fmod_flutter.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final fmod = FmodService();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initFmod();
  }

  Future<void> _initFmod() async {
    // Initialize
    final initialized = await fmod.initialize();
    if (!initialized) {
      print('FMOD initialization failed');
      return;
    }

    // Load banks
    final loaded = await fmod.loadBanks([
      'assets/audio/Master.bank',
      'assets/audio/Master.strings.bank',
      'assets/audio/Music.bank',
      'assets/audio/SFX.bank',
    ]);

    setState(() => _isReady = initialized && loaded);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('FMOD Flutter')),
        body: Center(
          child: _isReady
              ? ElevatedButton(
                  onPressed: () => fmod.playEvent('event:/main_music'),
                  child: Text('Play Music'),
                )
              : CircularProgressIndicator(),
        ),
      ),
    );
  }
}
```

### Step 5: Play Audio

```dart
// Play events
await fmod.playEvent('event:/main_music');
await fmod.playEvent('event:/gun_shoot');

// Stop events
await fmod.stopEvent('event:/main_music');

// Control parameters
await fmod.setParameter('event:/main_music', 'Intensity', 0.8);

// Pause/resume
await fmod.setPaused('event:/main_music', true);
await fmod.setPaused('event:/main_music', false);

// Volume control (0.0 to 1.0)
await fmod.setVolume('event:/main_music', 0.5);
```

---

## Platform Setup Details

### iOS

The setup script copies FMOD libraries to your app's `ios/FMOD/` directory:
- `ios/FMOD/include/` - Header files
- `ios/FMOD/lib/device/` - Device libraries (`libfmod_iphoneos.a`, `libfmodstudio_iphoneos.a`)
- `ios/FMOD/lib/simulator/` - Simulator libraries (`libfmod_iphonesimulator.a`, `libfmodstudio_iphonesimulator.a`)

The plugin's podspec automatically links the correct libraries for device vs simulator builds. **No Podfile modifications needed!**

**First build**: May take longer as CocoaPods processes FMOD libraries.

**Troubleshooting**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Android

✅ **Full JNI integration** - uses native C++ to call FMOD's C++ API via JNI (Java Native Interface).

The setup script copies FMOD files to your app:
- `android/app/src/main/jniLibs/*/libfmod.so` - native libraries
- `android/app/src/main/jniLibs/*/libfmodstudio.so` - native libraries  
- `android/app/libs/fmod/fmod.jar` - Java classes

Supported architectures:
- `arm64-v8a` (modern 64-bit devices)
- `armeabi-v7a` (older 32-bit devices)  
- `x86` & `x86_64` (emulators)

The plugin uses CMake to build the native JNI wrapper that bridges Kotlin to FMOD's C++ API. At build time, gradle copies the FMOD files from your app to the plugin.

**Troubleshooting**: Rerun `dart run fmod_flutter:setup_fmod` to restore libraries.

### Web (Experimental)

Add to `web/index.html` in `<head>`:

```html
<script src="fmod/fmodstudio.js" defer></script>
```

**Note**: Web support is experimental. Production builds may require additional configuration.

---

## .gitignore Configuration

### For Private/Closed-Source Projects

**You can commit FMOD files!** For your private game repository, it's often easier to commit:
- ✅ `engines/` (or the extracted SDK files)
- ✅ `android/app/src/main/jniLibs/libfmod*.so`
- ✅ `ios/FMOD/`
- ✅ `web/fmod/`

Your team members just clone and build - no setup needed!

### For Open Source / Public Repositories

**Don't commit FMOD files.** Add to your `.gitignore`:

```gitignore
# FMOD SDK files (proprietary - can't redistribute publicly)
engines/
android/app/src/main/jniLibs/libfmod*.so
android/app/libs/fmod/
ios/FMOD/
web/fmod/
```

Each user downloads FMOD with their own account and runs `dart run fmod_flutter:setup_fmod`.

**Why?** FMOD's license prohibits public redistribution. Anyone using your open source project must download FMOD themselves.

---

## API Reference

### FmodService

```dart
final fmod = FmodService();

// Initialize FMOD engine
Future<bool> initialize()

// Load bank files
Future<bool> loadBanks(List<String> paths)

// Play an event
Future<void> playEvent(String eventPath)

// Stop an event
Future<void> stopEvent(String eventPath)

// Set event parameter
Future<void> setParameter(String eventPath, String paramName, double value)

// Pause/resume event
Future<void> setPaused(String eventPath, bool paused)

// Set event volume (0.0 to 1.0)
Future<void> setVolume(String eventPath, double volume)

// Release resources (call on app shutdown)
Future<void> release()
```

---

## Troubleshooting

### "FMOD not initialized" or "Banks not loaded"

**Solution**: 
```bash
# Rerun setup
dart run fmod_flutter:setup_fmod

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### iOS: CocoaPods errors

**Solution**:
```bash
cd ios
pod deintegrate
rm Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

### Android: "Library not found"

**Solution**: Verify libraries exist:
```bash
ls -la android/app/src/main/jniLibs/arm64-v8a/
# Should show libfmod.so and libfmodstudio.so
```

If missing, rerun: `dart run fmod_flutter:setup_fmod`

### "Event not found"

**Solution**: 
- Verify event paths match FMOD Studio (case-sensitive!)
- Check console logs for available events
- Ensure banks are loaded before playing events

### Web: "FMOD not loaded"

**Solution**:
- Verify `web/fmod/fmodstudio.js` exists
- Check `web/index.html` includes script tag
- Try production build: `flutter build web`

---

## Team Workflow

### For Private Projects (Recommended)

**Commit FMOD files to your repo:**

Team setup:
1. One person runs `dart run fmod_flutter:setup_fmod`
2. Commit the generated `ios/FMOD/`, `android/.../jniLibs/`, etc.
3. Team members just clone and build - done!

### For Open Source Projects

**Each team member downloads FMOD:**

1. Clone your project
2. Run `flutter pub get`
3. Create `engines/` directory
4. Download FMOD SDKs from fmod.com (with their account)
5. Run `dart run fmod_flutter:setup_fmod`
6. Build and run!

(Don't commit `engines/` or FMOD native files - see .gitignore section)

---

## FMOD Resources

- **Download FMOD**: [fmod.com/download](https://www.fmod.com/download)
- **FMOD Documentation**: [fmod.com/docs](https://www.fmod.com/docs)
- **FMOD Studio**: [Video Tutorials](https://www.fmod.com/learn)
- **Licensing**: [fmod.com/licensing](https://www.fmod.com/licensing)
  - Free for indie (< $500k revenue/year)
  - Commercial licenses available

---

## License

**Plugin**: MIT License

**FMOD Engine**: Proprietary license from Firelight Technologies
- Free for indie developers
- Requires account at fmod.com
- See [fmod.com/licensing](https://www.fmod.com/licensing)

---

## Contributing

Contributions welcome! Please open an issue or PR on [GitHub](https://github.com/SuperWes/fmod_flutter).

---

## Example App

See `example/` directory for a complete demo with:
- Initialization flow
- Bank loading
- Music playback
- Sound effects
- Parameter control
- UI feedback

Run it: `cd example && flutter run`

---

## Support

- **Issues**: [GitHub Issues](https://github.com/SuperWes/fmod_flutter/issues)
- **Questions**: Open a discussion on GitHub
- **FMOD Help**: [FMOD Forums](https://qa.fmod.com/)

---

Made with 🎵 for Flutter game developers
