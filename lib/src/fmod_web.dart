import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'fmod_platform_interface.dart';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation of FmodPlatform using FMOD JavaScript/WASM API
class FmodWeb extends FmodPlatform {
  static void registerWith(Registrar registrar) {
    FmodPlatform.instance = FmodWeb();
  }

  bool _isInitialized = false;
  FMODSystem? _system;
  final Map<String, FMODEventInstance> _eventInstances = {};
  Timer? _updateTimer;

  @override
  Future<bool> initialize() async {
    try {
      // Wait for FMOD to load (retry up to 5 seconds)
      var attempts = 0;
      while (!_isFMODLoaded() && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // Check if FMOD Studio is loaded
      if (!_isFMODLoaded()) {
        print('FMOD Studio JavaScript API not loaded after ${attempts * 100}ms');
        print('Make sure fmodstudio.js is included in index.html and the file exists');
        print('Check browser console for 404 errors or script loading failures');
        return false;
      }
      
      print('FMOD JavaScript API detected after ${attempts * 100}ms');

      // Create FMOD Studio system
      _system = FMODSystem.create();
      if (_system == null) {
        print('Failed to create FMOD Studio system');
        return false;
      }

      // Initialize with 512 virtual channels
      final result = _system!.initialize(512);
      if (result != 0) {
        print('FMOD initialization failed with error code: $result');
        return false;
      }

      // Start update loop (60 Hz)
      _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        update();
      });

      _isInitialized = true;
      print('FMOD Web initialized successfully');
      return true;
    } catch (e) {
      print('FMOD Web initialization error: $e');
      return false;
    }
  }

  @override
  Future<bool> loadBanks(List<String> bankPaths) async {
    if (!_isInitialized || _system == null) return false;

    try {
      for (final path in bankPaths) {
        // For web, banks need to be loaded from the assets
        final fullPath = 'assets/$path';
        
        // Fetch the bank file as bytes
        try {
          final response = await html.HttpRequest.request(
            fullPath,
            responseType: 'arraybuffer',
          );
          
          if (response.status == 200) {
            final arrayBuffer = response.response as ByteBuffer;
            // Convert ByteBuffer to JSUint8Array for JS interop
            final uint8List = arrayBuffer.asUint8List();
            final jsArray = uint8List.toJS;
            final result = _system!.loadBankMemory(jsArray);
            
            if (result == 0) {
              print('Loaded bank: $path');
            } else {
              print('Failed to load bank $path with error code: $result');
            }
          } else {
            print('Failed to fetch bank $path: HTTP ${response.status}');
          }
        } catch (e) {
          print('Error loading bank $path: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Failed to load banks: $e');
      return false;
    }
  }

  @override
  Future<void> playEvent(String eventPath) async {
    if (!_isInitialized || _system == null) return;

    try {
      // Get event description
      final eventDesc = _system!.getEvent(eventPath);
      if (eventDesc == null) {
        print('Event not found: $eventPath');
        return;
      }

      // Check if event is already playing
      if (_eventInstances.containsKey(eventPath)) {
        final existing = _eventInstances[eventPath]!;
        final state = existing.getPlaybackState();
        if (state == 1 || state == 2) { // PLAYING or STARTING
          // Stop and restart
          existing.stop();
          existing.release();
        }
      }

      // Create new instance
      final instance = eventDesc.createInstance();
      if (instance == null) {
        print('Failed to create event instance for: $eventPath');
        return;
      }

      // Start the event
      instance.start();
      _eventInstances[eventPath] = instance;
      
      print('Playing event: $eventPath');
    } catch (e) {
      print('Failed to play event $eventPath: $e');
    }
  }

  @override
  Future<void> stopEvent(String eventPath) async {
    if (!_isInitialized) return;

    try {
      final instance = _eventInstances[eventPath];
      if (instance != null) {
        instance.stop();
        instance.release();
        _eventInstances.remove(eventPath);
        print('Stopped event: $eventPath');
      }
    } catch (e) {
      print('Failed to stop event $eventPath: $e');
    }
  }

  @override
  Future<void> setParameter(
      String eventPath, String paramName, double value) async {
    if (!_isInitialized) return;

    try {
      final instance = _eventInstances[eventPath];
      if (instance != null) {
        instance.setParameterByName(paramName, value);
      }
    } catch (e) {
      print('Failed to set parameter on $eventPath: $e');
    }
  }

  @override
  Future<void> setPaused(String eventPath, bool paused) async {
    if (!_isInitialized) return;

    try {
      final instance = _eventInstances[eventPath];
      if (instance != null) {
        instance.setPaused(paused);
      }
    } catch (e) {
      print('Failed to set paused state on $eventPath: $e');
    }
  }

  @override
  Future<void> setVolume(String eventPath, double volume) async {
    if (!_isInitialized) return;

    try {
      final instance = _eventInstances[eventPath];
      if (instance != null) {
        instance.setVolume(volume);
      }
    } catch (e) {
      print('Failed to set volume on $eventPath: $e');
    }
  }

  @override
  Future<void> update() async {
    if (!_isInitialized || _system == null) return;

    try {
      _system!.update();
    } catch (e) {
      // Silently handle update errors to avoid spam
    }
  }

  @override
  Future<void> release() async {
    if (!_isInitialized) return;

    try {
      // Stop update timer
      _updateTimer?.cancel();
      _updateTimer = null;

      // Release all event instances
      for (final instance in _eventInstances.values) {
        try {
          instance.stop();
          instance.release();
        } catch (e) {
          // Continue releasing others
        }
      }
      _eventInstances.clear();

      // Release system
      _system?.release();
      _system = null;

      _isInitialized = false;
      print('FMOD Web released');
    } catch (e) {
      print('Failed to release FMOD: $e');
    }
  }

  /// Check if FMOD JavaScript API is loaded
  bool _isFMODLoaded() {
    try {
      return js.globalContext.hasProperty('FMOD'.toJS).toDart;
    } catch (e) {
      return false;
    }
  }
}

/// JavaScript interop classes for FMOD Web API
/// These are placeholder definitions - actual implementation depends on FMOD's JS API

@js.JS('FMOD.Studio.System')
@js.staticInterop
class FMODSystem {
  external static FMODSystem? create();
}

extension FMODSystemExtension on FMODSystem {
  external int initialize(int maxChannels);
  external FMODEventDescription? getEvent(String path);
  external int loadBankMemory(js.JSUint8Array data);
  external void update();
  external void release();
}

@js.JS('FMOD.Studio.EventDescription')
@js.staticInterop
class FMODEventDescription {}

extension FMODEventDescriptionExtension on FMODEventDescription {
  external FMODEventInstance? createInstance();
}

@js.JS('FMOD.Studio.EventInstance')
@js.staticInterop
class FMODEventInstance {}

extension FMODEventInstanceExtension on FMODEventInstance {
  external void start();
  external void stop();
  external void release();
  external void setParameterByName(String name, double value);
  external void setPaused(bool paused);
  external void setVolume(double volume);
  external int getPlaybackState();
}

