import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'fmod_method_channel.dart';

/// The interface that implementations of fmod_flutter must implement.
abstract class FmodPlatform extends PlatformInterface {
  FmodPlatform() : super(token: _token);

  static final Object _token = Object();
  static FmodPlatform _instance = MethodChannelFmod();

  /// The default instance of [FmodPlatform] to use.
  static FmodPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FmodPlatform] when they register.
  static set instance(FmodPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the FMOD system
  Future<bool> initialize();

  /// Load FMOD banks from asset paths
  Future<bool> loadBanks(List<String> bankPaths);

  /// Play an FMOD event by path
  Future<void> playEvent(String eventPath);

  /// Stop a playing event
  Future<void> stopEvent(String eventPath);

  /// Set a parameter value on an event
  Future<void> setParameter(String eventPath, String paramName, double value);

  /// Pause or resume an event
  Future<void> setPaused(String eventPath, bool paused);

  /// Set the volume of an event
  Future<void> setVolume(String eventPath, double volume);

  /// Update the FMOD system (should be called regularly)
  Future<void> update();

  /// Release all FMOD resources
  Future<void> release();
}

