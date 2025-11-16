# FMOD Engine Files

**📌 This directory is for running the example app included with this plugin.**

## For Plugin Users

If you're using this plugin in your own Flutter app, **you don't need this directory**.

Instead, create `fmod_sdks/` in your project and follow the [main README](../README.md).

## For Running the Example App

### 1. Download FMOD

1. Go to [fmod.com/download](https://www.fmod.com/download)
2. Sign in (free account)
3. Download **FMOD Studio API** for your platforms:
   - iOS: `.dmg` file
   - Android: `.tar.gz` file
   - Web: `.zip` file

### 2. Place Files Here

```
engines/
├── fmodstudioapi*android.tar.gz
├── fmodstudioapi*ios-installer.dmg
├── fmodstudioapi*html5.zip
└── README.md (this file)
```

### 3. Run Setup

```bash
# From plugin root
dart tool/setup_fmod.dart
```

This extracts the SDKs and copies libraries to the example app.

### 4. Run Example

```bash
cd example
flutter run
```

---

**Note**: This directory is gitignored because FMOD files are proprietary and require individual licenses.
