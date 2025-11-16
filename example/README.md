# FMOD Flutter Example App

This example demonstrates FMOD audio integration in Flutter.

## Quick Run

### 1. Set Up FMOD (one time)

```bash
# From plugin root (one directory up)
cd ..

# Create engines directory
mkdir engines

# Download FMOD Studio API from fmod.com
# Place downloaded files in engines/

# Run setup script
dart tool/setup_fmod.dart
```

### 2. Run Example

```bash
# Back to example directory
cd example

# Run on your device
flutter run
```

## What It Demonstrates

- **Initialization**: Setting up FMOD engine
- **Bank Loading**: Loading audio banks
- **Music Playback**: Playing background music
- **Sound Effects**: Playing game sound effects
- **UI Integration**: Flutter widgets with FMOD
- **Error Handling**: Showing setup instructions when FMOD not configured

## Included Banks

The example includes sample FMOD banks with:
- **Music**: `event:/main_music`
- **Sound Effects**: 
  - `event:/gun_shoot`
  - `event:/gun_reload`
  - `event:/player_hurt`
  - `event:/player_death`
  - `event:/demon_growl`
  - And more...

## Using Your Own Audio

1. Create your project in FMOD Studio
2. Build your banks
3. Replace files in `assets/audio/`
4. Update event paths in `lib/main.dart`

## Troubleshooting

**"FMOD Not Ready" error**:
- Run setup script from plugin root: `dart tool/setup_fmod.dart`
- Ensure FMOD SDKs are in `../engines/`

**No sound on device**:
- Check device volume
- Verify banks are loaded (see console logs)
- Ensure event paths are correct

---

For full documentation, see the main [README.md](../README.md)
