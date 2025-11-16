# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-11-16

### Added
- Initial release of fmod_flutter plugin
- **Full iOS native implementation**:
  - FMOD C API integration via Objective-C bridge
  - iOS Audio Session configuration
  - 60Hz update loop for smooth audio
  - Event instance management
  - Comprehensive error handling
  - Tested and working with game audio
- **Full Android native implementation**:
  - FMOD Java/Kotlin API integration
  - Native `.so` library management for all architectures
  - Automatic setup via setup script
  - Ready for testing
- **Web/HTML5 implementation**:
  - JavaScript/WebAssembly integration using `dart:js_interop`
  - FMOD Studio JS API bindings
  - HTTP bank loading
  - 60Hz update loop
  - Requires API verification against FMOD version
- Automated setup system:
  - Dart-based setup script with archive extraction
  - Automatic library organization for iOS device/simulator
  - Android native library copying to jniLibs
  - Web WASM file management
  - Platform-specific file management
- Core FMOD functionality:
  - Initialize FMOD Studio system
  - Load FMOD banks from assets
  - Play/stop events with state tracking
  - Set event parameters dynamically
  - Control event volume and pause state
  - Bank inspection and event discovery
- Complete example app:
  - Beautiful Material Design UI
  - Real-time event control
  - Setup instructions for new users
  - Bank event discovery
  - Works with game audio (music, SFX)
- Comprehensive documentation:
  - Quick start guide
  - FMOD Studio setup guide
  - Platform-specific setup instructions
  - Android testing guide
  - Web implementation guide
  - Example integration code

### Technical Details
- **iOS**: Static library linking with CocoaPods integration, Objective-C bridge to C API
- **Android**: JNI native library integration, all architectures supported
- **Web**: dart:js_interop for FMOD JavaScript API, WASM loading
- Conditional imports for platform-specific code
- Proper .gitignore for FMOD engine files

### Tested Platforms
- ✅ **iOS**: Fully tested and working on physical device and simulator
- ⏳ **Android**: Implementation complete, ready for testing
- ⏳ **Web**: Implementation complete, may need API adjustments

### Notes
- FMOD Engine SDK must be downloaded separately (free for indie developers)
- Run `dart tool/setup_fmod.dart` after downloading SDKs
- See GETTING_FMOD_STUDIO.md for creating audio content
- See ANDROID_TESTING.md for Android setup
- See WEB_IMPLEMENTATION.md for web testing and API verification

