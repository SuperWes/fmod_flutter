/// A Flutter plugin for FMOD Studio audio engine integration.
///
/// This plugin allows you to play FMOD events, control parameters,
/// and manage audio playback in your Flutter applications.
library fmod_flutter;

export 'src/fmod_service.dart';
export 'src/fmod_platform_interface.dart';

// Web plugin registration - only import on web platforms
import 'src/fmod_web_stub.dart'
    if (dart.library.js_interop) 'src/fmod_web.dart';

void registerFmodWebPlugin() {
  // This is called automatically by Flutter web
}

