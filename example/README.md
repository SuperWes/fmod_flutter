# FMOD Flutter Example App

This example app demonstrates how to use the `fmod_flutter` plugin with your FMOD banks.

## Features

- ✅ FMOD system initialization
- ✅ Load multiple FMOD banks
- ✅ Play music events
- ✅ Play sound effects
- ✅ Event status tracking
- ✅ Stop events
- ✅ User-friendly UI with status feedback

## Quick Start

### 1. Setup FMOD Engine

Before running this example, you need to install FMOD Engine files. See:

```
../FMOD_SETUP.md
```

### 2. Update Event Paths

Open `lib/main.dart` and update the event paths to match your FMOD Studio project:

```dart
final List<String> _musicEvents = [
  'event:/Music/MainTheme',      // Update these to your actual events
  'event:/Music/BattleTheme',
  'event:/Music/AmbientTheme',
];

final List<String> _sfxEvents = [
  'event:/SFX/Jump',              // Update these to your actual events
  'event:/SFX/Click',
  'event:/SFX/Explosion',
];
```

### 3. Run the Example

```bash
cd packages/fmod_flutter/example
flutter pub get
flutter run
```

## What's Included

### FMOD Banks

The example includes your actual FMOD banks:
- `Master.bank`
- `Master.strings.bank`
- `Music.bank`
- `SFX.bank`

These are sample FMOD banks for demonstration purposes.

### Example Code

The `main.dart` demonstrates:

1. **Initialization**
   ```dart
   final fmod = FmodService();
   await fmod.initialize();
   ```

2. **Loading Banks**
   ```dart
   await fmod.loadBanks([
     'assets/audio/Master.bank',
     'assets/audio/Master.strings.bank',
     'assets/audio/Music.bank',
     'assets/audio/SFX.bank',
   ]);
   ```

3. **Playing Events**
   ```dart
   await fmod.playEvent('event:/Music/MainTheme');
   ```

4. **Stopping Events**
   ```dart
   await fmod.stopEvent('event:/Music/MainTheme');
   ```

## Finding Your Event Paths

To find the correct event paths:

1. Open your FMOD Studio project
2. Look at the Events Browser panel
3. Event paths follow: `event:/Folder/EventName`

For example:
- `event:/Music/MainTheme`
- `event:/SFX/TrapHit`

## Troubleshooting

### "FMOD not initialized"

Make sure you've installed FMOD Engine files. See `../FMOD_SETUP.md`.

### "Event not found"

Your event paths in `main.dart` don't match your FMOD project. Update them to match your actual events.

### No Sound

- Test on a real device (not simulator)
- Check device volume
- Look for errors in console logs

## Testing Tips

1. **Console Logs**: Check the console for FMOD debug messages
2. **Real Devices**: FMOD works best on physical devices
3. **Event Names**: Make sure event paths exactly match your FMOD Studio project (case-sensitive)
4. **Banks**: All required banks must be loaded (Master.bank and Master.strings.bank are essential)

## Next Steps

Once you have this working:

1. Experiment with different events
2. Try adding parameter controls
3. Test volume and pause/resume
4. Integrate into your actual game

Refer to the main plugin documentation in `../README.md` for more advanced features!
