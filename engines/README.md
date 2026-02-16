# FMOD Engine Files

**📌 This directory is for running the example app included with this plugin.**

## For Plugin Users

If you're using this plugin in your own Flutter app, **create `engines/` in YOUR project root** (not here).

Follow the setup instructions in the [main README](../README.md).

## For Running the Example App

### 1. Download FMOD

1. Go to [fmod.com/download](https://www.fmod.com/download)
2. Sign in (free account)
3. Download **FMOD Studio API** for your platforms:
   - iOS: `.dmg` file
   - macOS: `.dmg` file
   - Windows: `.exe` installer (**must be run first** — see below)
   - Android: `.tar.gz` file
   - Web: `.zip` file

### 2. Place Files Here

For iOS, macOS, Android, and Web, place the downloaded archives directly in this directory. The setup script will extract them automatically.

For **Windows**, the SDK comes as an `.exe` installer that cannot be extracted by the script:

1. Run `fmodstudioapi*win-installer.exe`
2. It installs to `C:\Program Files (x86)\FMOD SoundSystem\FMOD Studio API Windows\` by default
3. Copy the installed folder here as `windows/fmodstudioapi*win/`:
   ```powershell
   mkdir engines\windows\fmodstudioapi20312win
   xcopy "C:\Program Files (x86)\FMOD SoundSystem\FMOD Studio API Windows\*" engines\windows\fmodstudioapi20312win\ /E /I
   ```

```
engines/
├── fmodstudioapi*android.tar.gz
├── fmodstudioapi*ios-installer.dmg
├── fmodstudioapi*mac-installer.dmg
├── fmodstudioapi*html5.zip
├── windows/
│   └── fmodstudioapi20XXXwin/   (copied from install location)
│       └── api/
│           ├── core/
│           └── studio/
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
