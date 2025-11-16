# FMOD Engine Files

This directory should contain the FMOD Engine SDK files needed to build the plugin.

## Download FMOD Engine

1. Go to https://www.fmod.com/download
2. Create a free account or sign in
3. Download **FMOD Engine** (not FMOD Studio)
4. Download the following versions:
   - **FMOD Engine for iOS**
   - **FMOD Engine for Android**
   - **FMOD Engine for HTML5**

## Directory Structure

After downloading, extract the files and organize them as follows:

```
engines/
├── android/
│   └── fmodstudio20XXX/  (extracted Android SDK)
├── ios/
│   └── fmodstudioapi20XXX/  (extracted iOS SDK)
├── html5/
│   └── fmodstudio20XXX/  (extracted HTML5 SDK)
└── README.md (this file)
```

## Running the Setup Script

Once you've placed the FMOD SDKs in this directory, run:

```bash
# From the fmod_flutter package root
dart tool/setup_fmod.dart
```

This will automatically copy the necessary files to the correct locations in the plugin.

## License Note

⚠️ **IMPORTANT**: FMOD Engine is proprietary software with specific licensing terms:
- Free for indie developers (revenue < $500k/year)
- Requires purchase for larger commercial projects
- Cannot be redistributed (that's why this directory is gitignored)

See https://www.fmod.com/licensing for full details.

