package com.midnightlaunchgames.fmod_flutter

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FmodFlutterPlugin */
class FmodFlutterPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var fmodManager: FmodManager

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fmod_flutter")
    channel.setMethodCallHandler(this)
    fmodManager = FmodManager(context)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> {
        result.success(fmodManager.initialize())
      }
      "loadBanks" -> {
        val banks = call.argument<List<String>>("banks")
        if (banks != null) {
          result.success(fmodManager.loadBanks(banks))
        } else {
          result.error("INVALID_ARGS", "Banks list required", null)
        }
      }
      "playEvent" -> {
        val path = call.argument<String>("path")
        if (path != null) {
          fmodManager.playEvent(path)
          result.success(null)
        } else {
          result.error("INVALID_ARGS", "Event path required", null)
        }
      }
      "stopEvent" -> {
        val path = call.argument<String>("path")
        if (path != null) {
          fmodManager.stopEvent(path)
          result.success(null)
        } else {
          result.error("INVALID_ARGS", "Event path required", null)
        }
      }
      "setParameter" -> {
        val path = call.argument<String>("path")
        val param = call.argument<String>("parameter")
        val value = call.argument<Double>("value")
        if (path != null && param != null && value != null) {
          fmodManager.setParameter(path, param, value.toFloat())
          result.success(null)
        } else {
          result.error("INVALID_ARGS", "Path, parameter, and value required", null)
        }
      }
      "setPaused" -> {
        val path = call.argument<String>("path")
        val paused = call.argument<Boolean>("paused")
        if (path != null && paused != null) {
          fmodManager.setPaused(path, paused)
          result.success(null)
        } else {
          result.error("INVALID_ARGS", "Path and paused state required", null)
        }
      }
      "setMasterPaused" -> {
        val paused = call.argument<Boolean>("paused")
        if (paused != null) {
          result.success(fmodManager.setMasterPaused(paused))
        } else {
          result.error("INVALID_ARGS", "Paused state required", null)
        }
      }
      "setVolume" -> {
        val path = call.argument<String>("path")
        val volume = call.argument<Double>("volume")
        if (path != null && volume != null) {
          fmodManager.setVolume(path, volume.toFloat())
          result.success(null)
        } else {
          result.error("INVALID_ARGS", "Path and volume required", null)
        }
      }
      "update" -> {
        fmodManager.update()
        result.success(null)
      }
      "release" -> {
        fmodManager.release()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    fmodManager.release()
  }
}

