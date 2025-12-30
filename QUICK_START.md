# FMOD Flutter - Quick Start

## 5-Minute Setup

### 1. Add Plugin

```yaml
# pubspec.yaml
dependencies:
  fmod_flutter:
    git:
      url: https://github.com/SuperWes/fmod_flutter.git
```

```bash
flutter pub get
```

### 2. Get FMOD

1. Sign up at [fmod.com/download](https://www.fmod.com/download) (free)
2. Download **FMOD Studio API** for your platforms
3. Place in `engines/` directory in your project root

### 3. Run Setup

```bash
mkdir engines
# Add downloaded files to engines/
dart run fmod_flutter:setup_fmod
```

### 4. Add Audio Banks

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/audio/Master.bank
    - assets/audio/Master.strings.bank
```

### 5. Use It!

```dart
import 'package:fmod_flutter/fmod_flutter.dart';

final fmod = FmodService();

// Initialize
await fmod.initialize();
await fmod.loadBanks(['assets/audio/Master.bank']);

// Play
await fmod.playEvent('event:/Music/MainTheme');
```

## .gitignore

Add this to `.gitignore` (for public/open-source projects):

```gitignore
engines/
android/app/src/main/jniLibs/libfmod*.so
android/app/libs/fmod/
ios/FMOD/
web/fmod/
```

For **private projects**, you can commit these files so your team doesn't need to run setup.

---

**Full guide**: See [README.md](README.md)
