import 'package:flutter/services.dart';
import 'fmod_platform_interface.dart';

/// An implementation of [FmodPlatform] that uses method channels.
class MethodChannelFmod extends FmodPlatform {
  final MethodChannel _channel = const MethodChannel('fmod_flutter');

  @override
  Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      return result ?? false;
    } catch (e) {
      throw Exception('Failed to initialize FMOD: $e');
    }
  }

  @override
  Future<bool> loadBanks(List<String> bankPaths) async {
    try {
      final result = await _channel.invokeMethod<bool>('loadBanks', {
        'banks': bankPaths,
      });
      return result ?? false;
    } catch (e) {
      throw Exception('Failed to load banks: $e');
    }
  }

  @override
  Future<void> playEvent(String eventPath) async {
    await _channel.invokeMethod('playEvent', {'path': eventPath});
  }

  @override
  Future<void> stopEvent(String eventPath) async {
    await _channel.invokeMethod('stopEvent', {'path': eventPath});
  }

  @override
  Future<void> setParameter(
    String eventPath,
    String paramName,
    double value,
  ) async {
    await _channel.invokeMethod('setParameter', {
      'path': eventPath,
      'parameter': paramName,
      'value': value,
    });
  }

  @override
  Future<void> setPaused(String eventPath, bool paused) async {
    await _channel.invokeMethod('setPaused', {
      'path': eventPath,
      'paused': paused,
    });
  }

  @override
  Future<void> setVolume(String eventPath, double volume) async {
    await _channel.invokeMethod('setVolume', {
      'path': eventPath,
      'volume': volume,
    });
  }

  @override
  Future<void> update() async {
    await _channel.invokeMethod('update');
  }

  @override
  Future<void> release() async {
    await _channel.invokeMethod('release');
  }

  @override
  Future<void> setMasterPaused(bool paused) async {
    await _channel.invokeMethod('setMasterPaused', {'paused': paused});
  }
}

