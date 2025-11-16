# fmod_flutter

A Flutter plugin for FMOD Studio audio engine integration. Play advanced game audio with FMOD's powerful features including 3D audio, real-time parameter control, and professional mixing.

## Features

- ✅ Play FMOD events
- ✅ Control event parameters in real-time
- ✅ Pause/resume events
- ✅ Volume control per event
- ✅ Load multiple FMOD banks
- ✅ Cross-platform (Android, iOS & Web)

## Example App

A complete example app is included in the `example/` directory. It demonstrates:

- FMOD initialization
- Loading banks
- Playing music and sound effects
- Event management
- UI with status feedback

To run the example:

```bash
cd example
flutter pub get
flutter run
```

See `example/README.md` for details.

## Getting Started

### Setup FMOD Engine

Before using this plugin, you must install the FMOD Engine native libraries:

**Quick Setup (Recommended):**

1. Download FMOD Engine from https://www.fmod.com/download (requires free account)
2. Extract SDKs to the `engines/` directory (see `engines/README.md` for structure)
3. Run the setup script:
   ```bash
   cd packages/fmod_flutter
   dart tool/setup_fmod.dart
   ```

The script will automatically copy all necessary files to the correct locations for Android, iOS, and Web.

**Manual Setup:**

See [FMOD_SETUP.md](FMOD_SETUP.md) for detailed platform-specific instructions.

### Platform-Specific Notes

#### Android Setup (Manual)

1. Extract FMOD for Android
2. Copy `fmod.jar` to `packages/fmod_flutter/android/libs/`
3. Copy native libraries (`.so` files) to `android/app/src/main/jniLibs/`:
   ```
   android/app/src/main/jniLibs/
   ├── arm64-v8a/
   │   └── libfmod.so
   ├── armeabi-v7a/
   │   └── libfmod.so
   └── x86/
       └── libfmod.so
   ```

### iOS Setup

1. Extract FMOD for iOS
2. Copy `fmod.framework` to `packages/fmod_flutter/ios/Frameworks/`
3. In your iOS app's Xcode project:
   - Add `fmod.framework` to "Frameworks, Libraries, and Embedded Content"
   - Ensure it's set to "Embed & Sign"

### Add FMOD Banks to Your App

1. Export your FMOD Studio banks (Master.bank, Master.strings.bank, etc.)
2. Place them in your Flutter app's `assets/audio/` directory
3. Update your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/audio/Master.bank
    - assets/audio/Master.strings.bank
    - assets/audio/Music.bank
    - assets/audio/SFX.bank
```

## Usage

### Initialize FMOD

```dart
import 'package:fmod_flutter/fmod_flutter.dart';

// Create service
final fmod = FmodService();

// Initialize
await fmod.initialize();

// Load banks
await fmod.loadBanks([
  'assets/audio/Master.bank',
  'assets/audio/Master.strings.bank',
  'assets/audio/Music.bank',
  'assets/audio/SFX.bank',
]);
```

### Play Events

```dart
// Play background music
await fmod.playEvent('event:/Music/MainTheme');

// Play sound effects
await fmod.playEvent('event:/SFX/Jump');
await fmod.playEvent('event:/SFX/Explosion');
```

### Control Events

```dart
// Stop an event
await fmod.stopEvent('event:/Music/MainTheme');

// Set a parameter (e.g., music intensity)
await fmod.setParameter('event:/Music/MainTheme', 'Intensity', 0.8);

// Pause/resume
await fmod.setPaused('event:/Music/MainTheme', true);
await fmod.setPaused('event:/Music/MainTheme', false);

// Set volume (0.0 to 1.0)
await fmod.setVolume('event:/Music/MainTheme', 0.5);
```

### Update Loop (Optional)

For the best performance, call `update()` in your game loop:

```dart
// In your game's update method
@override
void update(double dt) {
  super.update(dt);
  fmod.update();
}
```

### Cleanup

```dart
@override
void dispose() {
  fmod.dispose();
  super.dispose();
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:fmod_flutter/fmod_flutter.dart';

class AudioExample extends StatefulWidget {
  @override
  _AudioExampleState createState() => _AudioExampleState();
}

class _AudioExampleState extends State<AudioExample> {
  final fmod = FmodService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFmod();
  }

  Future<void> _initializeFmod() async {
    await fmod.initialize();
    await fmod.loadBanks([
      'assets/audio/Master.bank',
      'assets/audio/Master.strings.bank',
      'assets/audio/Music.bank',
    ]);
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FMOD Example')),
      body: _isInitialized
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: () => fmod.playEvent('event:/Music/MainTheme'),
                  child: Text('Play Music'),
                ),
                ElevatedButton(
                  onPressed: () => fmod.playEvent('event:/SFX/Click'),
                  child: Text('Play SFX'),
                ),
                ElevatedButton(
                  onPressed: () => fmod.stopEvent('event:/Music/MainTheme'),
                  child: Text('Stop Music'),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    fmod.dispose();
    super.dispose();
  }
}
```

## License

This plugin itself is MIT licensed. FMOD Studio is a commercial product and requires a license from Firelight Technologies. See https://www.fmod.com/licensing for details.

## FMOD Licensing

**Important**: This plugin is just a Flutter wrapper. You must obtain appropriate FMOD licenses:

- **Indie License**: Free for small developers (revenue < $200k/year)
- **Commercial License**: Required for larger projects

Visit https://www.fmod.com/licensing for full details.

## Troubleshooting

### Android: "UnsatisfiedLinkError: dlopen failed"

Make sure you've placed the FMOD `.so` files in the correct `jniLibs` directories for all architectures you're targeting.

### iOS: "dyld: Library not loaded"

Ensure `fmod.framework` is properly embedded in your iOS app and set to "Embed & Sign" in Xcode.

### Events not playing

- Verify your event paths match exactly what's in FMOD Studio (case-sensitive)
- Make sure you've loaded all required banks (Master.bank and Master.strings.bank are usually required)
- Check console logs for FMOD error messages

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

