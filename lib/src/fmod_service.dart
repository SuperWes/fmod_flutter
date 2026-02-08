import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'fmod_platform_interface.dart';

/// High-level service for managing FMOD audio in Flutter applications.
///
/// Example usage:
/// ```dart
/// final fmod = FmodService();
/// await fmod.initialize();
/// await fmod.loadBanks([
///   'assets/audio/Master.bank',
///   'assets/audio/Master.strings.bank',
/// ]);
/// await fmod.playEvent('event:/Music/MainTheme');
/// ```
class FmodService with WidgetsBindingObserver {
  final FmodPlatform _platform = FmodPlatform.instance;

  bool _isInitialized = false;
  final Map<String, bool> _playingEvents = {};
  final Map<String, bool> _pausedBySystem = {};
  bool _isPausedByLifecycle = false;

  /// Whether FMOD has been successfully initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the FMOD system.
  ///
  /// This must be called before any other FMOD operations.
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _platform.initialize();
      if (_isInitialized) {
        // Register lifecycle observer to handle app backgrounding
        WidgetsBinding.instance.addObserver(this);
      }
      debugPrint('FMOD initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize FMOD: $e');
      return false;
    }
  }

  /// Load FMOD banks from asset paths.
  ///
  /// Example:
  /// ```dart
  /// await fmod.loadBanks([
  ///   'assets/audio/Master.bank',
  ///   'assets/audio/Master.strings.bank',
  ///   'assets/audio/Music.bank',
  ///   'assets/audio/SFX.bank',
  /// ]);
  /// ```
  ///
  /// The asset paths should match the paths in your pubspec.yaml.
  /// Returns true if all banks loaded successfully.
  Future<bool> loadBanks(List<String> bankPaths) async {
    if (!_isInitialized) {
      throw StateError('FMOD must be initialized before loading banks');
    }

    try {
      final result = await _platform.loadBanks(bankPaths);
      debugPrint('FMOD banks loaded: $result');
      return result;
    } catch (e) {
      debugPrint('Failed to load banks: $e');
      return false;
    }
  }

  /// Play an FMOD event by its path.
  ///
  /// Example:
  /// ```dart
  /// await fmod.playEvent('event:/Music/MainTheme');
  /// await fmod.playEvent('event:/SFX/Jump');
  /// ```
  ///
  /// The event path must match an event defined in your FMOD project.
  Future<void> playEvent(String eventPath) async {
    if (!_isInitialized) return;

    try {
      await _platform.playEvent(eventPath);
      _playingEvents[eventPath] = true;
      debugPrint('Playing FMOD event: $eventPath');
    } catch (e) {
      debugPrint('Failed to play event $eventPath: $e');
    }
  }

  /// Stop a playing FMOD event.
  ///
  /// The event will fade out if configured in FMOD Studio.
  Future<void> stopEvent(String eventPath) async {
    if (!_isInitialized) return;

    try {
      await _platform.stopEvent(eventPath);
      _playingEvents[eventPath] = false;
      debugPrint('Stopped FMOD event: $eventPath');
    } catch (e) {
      debugPrint('Failed to stop event $eventPath: $e');
    }
  }

  /// Set a parameter value on a playing event.
  ///
  /// Example:
  /// ```dart
  /// await fmod.setParameter('event:/Music/MainTheme', 'Intensity', 0.8);
  /// ```
  ///
  /// Parameters must be defined in your FMOD Studio project.
  Future<void> setParameter(
    String eventPath,
    String paramName,
    double value,
  ) async {
    if (!_isInitialized) return;

    try {
      await _platform.setParameter(eventPath, paramName, value);
    } catch (e) {
      debugPrint('Failed to set parameter on $eventPath: $e');
    }
  }

  /// Pause or resume a playing event.
  Future<void> setPaused(String eventPath, bool paused) async {
    if (!_isInitialized) return;

    try {
      await _platform.setPaused(eventPath, paused);
    } catch (e) {
      debugPrint('Failed to set paused state on $eventPath: $e');
    }
  }

  /// Pause all audio by pausing the master bus.
  ///
  /// This is more reliable than tracking individual events.
  /// Use this when the app goes to background.
  Future<void> pauseAllAudio() async {
    if (!_isInitialized) return;
    try {
      await _platform.setMasterPaused(true);
      debugPrint('FMOD: Master bus paused');
    } catch (e) {
      debugPrint('Failed to pause master bus: $e');
    }
  }

  /// Resume all audio by unpausing the master bus.
  ///
  /// Call this when the app returns to foreground.
  Future<void> resumeAllAudio() async {
    if (!_isInitialized) return;
    try {
      await _platform.setMasterPaused(false);
      debugPrint('FMOD: Master bus resumed');
    } catch (e) {
      debugPrint('Failed to resume master bus: $e');
    }
  }


  /// Set the volume for a playing event.
  ///
  /// Volume should be between 0.0 (silent) and 1.0 (full volume).
  Future<void> setVolume(String eventPath, double volume) async {
    if (!_isInitialized) return;

    try {
      await _platform.setVolume(eventPath, volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Failed to set volume on $eventPath: $e');
    }
  }

  /// Update the FMOD system.
  ///
  /// This should be called regularly (e.g., in a game loop) to process
  /// audio updates. If not called manually, FMOD will update automatically
  /// but less frequently.
  Future<void> update() async {
    if (!_isInitialized) return;
    await _platform.update();
  }

  /// Release all FMOD resources.
  ///
  /// This should be called when you're done using FMOD, typically when
  /// the app is closing.
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      WidgetsBinding.instance.removeObserver(this);
      await _platform.release();
      _isInitialized = false;
      _playingEvents.clear();
      _pausedBySystem.clear();
      debugPrint('FMOD released');
    } catch (e) {
      debugPrint('Failed to release FMOD: $e');
    }
  }

  /// Check if an event is currently playing.
  bool isEventPlaying(String eventPath) {
    return _playingEvents[eventPath] ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background - pause all playing events
        pauseAllAudio();
        break;
      case AppLifecycleState.resumed:
        // App is coming back - resume previously playing events
        resumeAllAudio();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Pause all currently playing events when app goes to background
  void _pauseAllEvents() {
    if (_isPausedByLifecycle) return;
    
    _isPausedByLifecycle = true;
    _pausedBySystem.clear();
    
    for (var entry in _playingEvents.entries) {
      if (entry.value) {
        // This event is playing, pause it
        setPaused(entry.key, true);
        _pausedBySystem[entry.key] = true;
      }
    }
    debugPrint('FMOD: Paused ${_pausedBySystem.length} events (app backgrounded)');
  }

  /// Resume events that were paused by the system when app returns to foreground
  void _resumeAllEvents() {
    if (!_isPausedByLifecycle) return;
    
    _isPausedByLifecycle = false;
    
    for (var eventPath in _pausedBySystem.keys) {
      // Only resume events that were paused by the system, not by user
      setPaused(eventPath, false);
    }
    debugPrint('FMOD: Resumed ${_pausedBySystem.length} events (app resumed)');
    _pausedBySystem.clear();
  }
}

