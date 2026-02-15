import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'fmod_platform_interface.dart';

/// Web implementation of FmodPlatform using FMOD's Emscripten-compiled WASM API.
///
/// The FMOD HTML5 SDK is an Emscripten module. Initialization works as follows:
///   1. A global `FMOD` config object is created with callbacks
///   2. `FMODModule(FMOD)` is called (from the loaded fmodstudio.js)
///   3. `preRun` callback fires — preload bank files into the Emscripten FS
///   4. `onRuntimeInitialized` fires — create the Studio System and initialize
///   5. All subsequent API calls go through the augmented `FMOD` global and
///      the system/event objects it produces, using an `{val: ...}` outval pattern.
class FmodWeb extends FmodPlatform {
  static void registerWith(Registrar registrar) {
    FmodPlatform.instance = FmodWeb();
  }

  bool _isInitialized = false;

  /// The FMOD global object (Emscripten module instance).
  JSObject? _fmod;

  /// The Studio System object.
  JSObject? _system;

  /// The Core System object.
  JSObject? _systemCore;

  /// Tracks active event instances by event path.
  final Map<String, JSObject> _eventInstances = {};

  Timer? _updateTimer;

  /// Bank paths queued for preloading before FMOD runtime init.
  List<String> _pendingBankPaths = [];

  /// Completer that resolves when FMOD's onRuntimeInitialized fires.
  Completer<bool>? _initCompleter;

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Create a fresh `{}` JS object (for FMOD outval pattern).
  JSObject _newOutval() {
    final ctor = globalContext.getProperty('Object'.toJS) as JSFunction;
    return ctor.callAsConstructor() as JSObject;
  }

  /// Call a method on [obj] with variable args, return FMOD result code (int).
  int _call(JSObject obj, String method, [List<JSAny?> args = const []]) {
    final result = obj.callMethodVarArgs(method.toJS, args);
    return (result as JSNumber).toDartInt;
  }

  /// Read the `val` property from an FMOD outval object.
  JSObject _outVal(JSObject outval) {
    return outval.getProperty('val'.toJS) as JSObject;
  }

  /// Read a property from the FMOD global (e.g. `FMOD.OK`).
  JSAny? _fmodProp(String name) => _fmod?.getProperty(name.toJS);

  /// Read an integer constant from the FMOD global.
  int _fmodConst(String name) => (_fmodProp(name) as JSNumber).toDartInt;

  // ------------------------------------------------------------------
  // Platform interface
  // ------------------------------------------------------------------

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // fmodstudio.js must define FMODModule globally
      if (!globalContext.hasProperty('FMODModule'.toJS).toDart) {
        print(
          '[FMOD Web] FMODModule not found. '
          'Make sure fmodstudio.js is loaded in index.html before flutter_bootstrap.js',
        );
        return false;
      }

      _initCompleter = Completer<bool>();

      // Build the FMOD config object
      final fmod = _newOutval();
      globalContext.setProperty('FMOD'.toJS, fmod);
      _fmod = fmod;

      // Set initial memory (64 MB)
      fmod.setProperty('INITIAL_MEMORY'.toJS, (64 * 1024 * 1024).toJS);

      // preRun: preload bank files into the Emscripten virtual FS
      fmod.setProperty(
        'preRun'.toJS,
        (() {
          _preloadBanks();
        }).toJS,
      );

      // onRuntimeInitialized: create the Studio System and initialize
      fmod.setProperty(
        'onRuntimeInitialized'.toJS,
        (() {
          _onRuntimeInitialized();
        }).toJS,
      );

      // Kick off the Emscripten module
      final fmodModuleFn =
          globalContext.getProperty('FMODModule'.toJS) as JSFunction;
      fmodModuleFn.callAsFunction(null, fmod);

      // Wait for onRuntimeInitialized (with timeout)
      return await _initCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[FMOD Web] Timed out waiting for FMOD runtime init');
          return false;
        },
      );
    } catch (e) {
      print('[FMOD Web] initialization error: $e');
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(false);
      }
      return false;
    }
  }

  /// Preload pending bank files into Emscripten's virtual filesystem.
  void _preloadBanks() {
    if (_fmod == null) return;
    for (final bankPath in _pendingBankPaths) {
      final fileName = bankPath.split('/').last;
      final fileUrl = 'assets/$bankPath';
      try {
        _fmod!.callMethodVarArgs('FS_createPreloadedFile'.toJS, [
          '/'.toJS,
          fileName.toJS,
          fileUrl.toJS,
          true.toJS,
          false.toJS,
        ]);
        print('[FMOD Web] Preloading bank: $fileName from $fileUrl');
      } catch (e) {
        print('[FMOD Web] Failed to preload $fileName: $e');
      }
    }
  }

  /// Called when the Emscripten runtime has initialized.
  void _onRuntimeInitialized() {
    try {
      final fmod = _fmod!;
      final ok = _fmodConst('OK');

      // FMOD.Studio_System_Create(outval)
      final sysOutval = _newOutval();
      if (_call(fmod, 'Studio_System_Create', [sysOutval]) != ok) {
        print('[FMOD Web] Studio_System_Create failed');
        _initCompleter?.complete(false);
        return;
      }
      _system = _outVal(sysOutval);

      // system.getCoreSystem(outval)
      final coreOutval = _newOutval();
      if (_call(_system!, 'getCoreSystem', [coreOutval]) != ok) {
        print('[FMOD Web] getCoreSystem failed');
        _initCompleter?.complete(false);
        return;
      }
      _systemCore = _outVal(coreOutval);

      // Set DSP buffer size for browser compatibility
      _call(_systemCore!, 'setDSPBufferSize', [2048.toJS, 2.toJS]);

      // system.initialize(maxChannels, studioFlags, coreFlags, extraDriverData)
      final initResult = _call(_system!, 'initialize', [
        1024.toJS,
        _fmodProp('STUDIO_INIT_NORMAL'),
        _fmodProp('INIT_NORMAL'),
        null,
      ]);
      if (initResult != ok) {
        print('[FMOD Web] System initialize failed: $initResult');
        _initCompleter?.complete(false);
        return;
      }

      // Start update loop (50 Hz, matching FMOD examples)
      _updateTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
        _doUpdate();
      });

      _isInitialized = true;
      print('[FMOD Web] Initialized successfully');
      _initCompleter?.complete(true);
    } catch (e) {
      print('[FMOD Web] onRuntimeInitialized error: $e');
      _initCompleter?.complete(false);
    }
  }

  @override
  Future<bool> loadBanks(List<String> bankPaths) async {
    if (!_isInitialized || _system == null) {
      if (!_isInitialized) {
        // Queue for preloading during initialize()
        _pendingBankPaths = bankPaths;
        return true;
      }
      return false;
    }

    try {
      final ok = _fmodConst('OK');
      final loadFlag = _fmodProp('STUDIO_LOAD_BANK_NORMAL');

      for (final path in bankPaths) {
        final fileName = path.split('/').last;

        // Try loading from the Emscripten FS (if preloaded in preRun)
        final bankOutval = _newOutval();
        final result = _call(_system!, 'loadBankFile', [
          '/$fileName'.toJS,
          loadFlag,
          bankOutval,
        ]);

        if (result == ok) {
          print('[FMOD Web] Loaded bank: $fileName');
        } else {
          // Fetch from network, write to Emscripten FS, then load
          print(
            '[FMOD Web] Bank $fileName not in FS, fetching from network...',
          );
          if (!await _loadBankFromUrl(path)) {
            print('[FMOD Web] Could not load bank $fileName');
          }
        }
      }

      return true;
    } catch (e) {
      print('[FMOD Web] loadBanks error: $e');
      return false;
    }
  }

  /// Fetch a bank file from a URL, write it to the Emscripten virtual FS,
  /// and load it via loadBankFile.
  Future<bool> _loadBankFromUrl(String bankPath) async {
    try {
      final ok = _fmodConst('OK');
      final fileName = bankPath.split('/').last;
      final fileUrl = 'assets/$bankPath';

      // Fetch via browser fetch API
      final response =
          await (globalContext.callMethodVarArgs('fetch'.toJS, [fileUrl.toJS])
                  as JSPromise)
              .toDart;
      final jsResponse = response as JSObject;

      if (!(jsResponse.getProperty('ok'.toJS) as JSBoolean).toDart) {
        print('[FMOD Web] Fetch failed for $fileUrl');
        return false;
      }

      final arrayBuffer =
          await (jsResponse.callMethodVarArgs('arrayBuffer'.toJS) as JSPromise)
              .toDart;

      // Create Uint8Array from ArrayBuffer
      final uint8Ctor =
          globalContext.getProperty('Uint8Array'.toJS) as JSFunction;
      final uint8Array = uint8Ctor.callAsConstructor(arrayBuffer) as JSObject;

      // Write to Emscripten FS
      _writeToEmscriptenFS(fileName, uint8Array);

      // Load the bank
      final bankOutval = _newOutval();
      final result = _call(_system!, 'loadBankFile', [
        '/$fileName'.toJS,
        _fmodProp('STUDIO_LOAD_BANK_NORMAL'),
        bankOutval,
      ]);

      if (result == ok) {
        print('[FMOD Web] Loaded bank from network: $fileName');
        return true;
      } else {
        print('[FMOD Web] loadBankFile failed for $fileName, result=$result');
        return false;
      }
    } catch (e) {
      print('[FMOD Web] _loadBankFromUrl error: $e');
      return false;
    }
  }

  /// Write data to the Emscripten virtual FS, unlinking first if file exists.
  void _writeToEmscriptenFS(String fileName, JSObject uint8Array) {
    try {
      _fmod!.callMethodVarArgs('FS_createDataFile'.toJS, [
        '/'.toJS,
        fileName.toJS,
        uint8Array,
        true.toJS,
        false.toJS,
      ]);
    } catch (_) {
      // File may already exist — unlink and retry
      try {
        final fs = _fmod!.getProperty('FS'.toJS) as JSObject;
        fs.callMethodVarArgs('unlink'.toJS, ['/$fileName'.toJS]);
      } catch (_) {}
      _fmod!.callMethodVarArgs('FS_createDataFile'.toJS, [
        '/'.toJS,
        fileName.toJS,
        uint8Array,
        true.toJS,
        false.toJS,
      ]);
    }
  }

  @override
  Future<void> playEvent(String eventPath) async {
    if (!_isInitialized || _system == null) return;

    try {
      final ok = _fmodConst('OK');

      // Stop existing instance if playing
      if (_eventInstances.containsKey(eventPath)) {
        try {
          _call(_eventInstances[eventPath]!, 'stop', [
            _fmodProp('STUDIO_STOP_IMMEDIATE'),
          ]);
          _eventInstances[eventPath]!.callMethodVarArgs('release'.toJS);
        } catch (_) {}
        _eventInstances.remove(eventPath);
      }

      // system.getEvent(path, outval)
      final descOutval = _newOutval();
      final descResult = _call(_system!, 'getEvent', [
        eventPath.toJS,
        descOutval,
      ]);
      if (descResult != ok) {
        print('[FMOD Web] getEvent failed for $eventPath, result=$descResult');
        return;
      }
      final eventDesc = _outVal(descOutval);

      // eventDesc.createInstance(outval)
      final instOutval = _newOutval();
      final instResult = _call(eventDesc, 'createInstance', [instOutval]);
      if (instResult != ok) {
        print(
          '[FMOD Web] createInstance failed for $eventPath, result=$instResult',
        );
        return;
      }
      final instance = _outVal(instOutval);

      // instance.start()
      final startResult = _call(instance, 'start');
      if (startResult != ok) {
        print('[FMOD Web] start failed for $eventPath, result=$startResult');
        return;
      }

      _eventInstances[eventPath] = instance;
      print('[FMOD Web] Playing: $eventPath');
    } catch (e) {
      print('[FMOD Web] playEvent error for $eventPath: $e');
    }
  }

  @override
  Future<void> stopEvent(String eventPath) async {
    if (!_isInitialized) return;

    final instance = _eventInstances[eventPath];
    if (instance == null) return;

    try {
      _call(instance, 'stop', [_fmodProp('STUDIO_STOP_ALLOWFADEOUT')]);
      instance.callMethodVarArgs('release'.toJS);
      _eventInstances.remove(eventPath);
      print('[FMOD Web] Stopped: $eventPath');
    } catch (e) {
      print('[FMOD Web] stopEvent error for $eventPath: $e');
    }
  }

  @override
  Future<void> setParameter(
    String eventPath,
    String paramName,
    double value,
  ) async {
    if (!_isInitialized) return;
    final instance = _eventInstances[eventPath];
    if (instance == null) return;
    try {
      _call(instance, 'setParameterByName', [
        paramName.toJS,
        value.toJS,
        false.toJS,
      ]);
    } catch (e) {
      print('[FMOD Web] setParameter error on $eventPath: $e');
    }
  }

  @override
  Future<void> setPaused(String eventPath, bool paused) async {
    if (!_isInitialized) return;
    final instance = _eventInstances[eventPath];
    if (instance == null) return;
    try {
      _call(instance, 'setPaused', [paused.toJS]);
    } catch (e) {
      print('[FMOD Web] setPaused error on $eventPath: $e');
    }
  }

  @override
  Future<void> setVolume(String eventPath, double volume) async {
    if (!_isInitialized) return;
    final instance = _eventInstances[eventPath];
    if (instance == null) return;
    try {
      _call(instance, 'setVolume', [volume.toJS]);
    } catch (e) {
      print('[FMOD Web] setVolume error on $eventPath: $e');
    }
  }

  @override
  Future<void> setMasterPaused(bool paused) async {
    if (!_isInitialized || _system == null) return;
    try {
      final busOutval = _newOutval();
      if (_call(_system!, 'getBus', ['bus:/'.toJS, busOutval]) ==
          _fmodConst('OK')) {
        _call(_outVal(busOutval), 'setPaused', [paused.toJS]);
      }
    } catch (e) {
      print('[FMOD Web] setMasterPaused error: $e');
    }
  }

  @override
  Future<void> update() async => _doUpdate();

  void _doUpdate() {
    if (!_isInitialized || _system == null) return;
    try {
      _system!.callMethodVarArgs('update'.toJS);
    } catch (_) {}
  }

  @override
  Future<void> release() async {
    if (!_isInitialized) return;
    try {
      _updateTimer?.cancel();
      _updateTimer = null;
      for (final instance in _eventInstances.values) {
        try {
          _call(instance, 'stop', [_fmodProp('STUDIO_STOP_IMMEDIATE')]);
          instance.callMethodVarArgs('release'.toJS);
        } catch (_) {}
      }
      _eventInstances.clear();
      if (_system != null) {
        try {
          _system!.callMethodVarArgs('release'.toJS);
        } catch (_) {}
        _system = null;
      }
      _systemCore = null;
      _isInitialized = false;
      print('[FMOD Web] Released');
    } catch (e) {
      print('[FMOD Web] release error: $e');
    }
  }

  /// Set bank paths before calling [initialize].
  /// Banks will be preloaded into the Emscripten virtual FS during preRun.
  void setBankPaths(List<String> paths) {
    _pendingBankPaths = paths;
  }
}
