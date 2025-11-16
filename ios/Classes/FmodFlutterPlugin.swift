import Flutter
import UIKit

public class FmodFlutterPlugin: NSObject, FlutterPlugin {
    private var fmodManager: FmodManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fmod_flutter", binaryMessenger: registrar.messenger())
        let instance = FmodFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(result: result)
        case "loadBanks":
            handleLoadBanks(call: call, result: result)
        case "playEvent":
            handlePlayEvent(call: call, result: result)
        case "stopEvent":
            handleStopEvent(call: call, result: result)
        case "setParameter":
            handleSetParameter(call: call, result: result)
        case "setPaused":
            handleSetPaused(call: call, result: result)
        case "setVolume":
            handleSetVolume(call: call, result: result)
        case "update":
            fmodManager?.update()
            result(nil)
        case "release":
            fmodManager?.release()
            fmodManager = nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleInitialize(result: @escaping FlutterResult) {
        fmodManager = FmodManager()
        let success = fmodManager?.initialize() ?? false
        result(success)
    }
    
    private func handleLoadBanks(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let banks = args["banks"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Banks list required", details: nil))
            return
        }
        
        let success = fmodManager?.loadBanks(banks) ?? false
        result(success)
    }
    
    private func handlePlayEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Event path required", details: nil))
            return
        }
        
        fmodManager?.playEvent(path)
        result(nil)
    }
    
    private func handleStopEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Event path required", details: nil))
            return
        }
        
        fmodManager?.stopEvent(path)
        result(nil)
    }
    
    private func handleSetParameter(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let parameter = args["parameter"] as? String,
              let value = args["value"] as? Double else {
            result(FlutterError(code: "INVALID_ARGS", message: "Path, parameter, and value required", details: nil))
            return
        }
        
        fmodManager?.setParameter(path: path, paramName: parameter, value: Float(value))
        result(nil)
    }
    
    private func handleSetPaused(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let paused = args["paused"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "Path and paused state required", details: nil))
            return
        }
        
        fmodManager?.setPaused(path: path, paused: paused)
        result(nil)
    }
    
    private func handleSetVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let volume = args["volume"] as? Double else {
            result(FlutterError(code: "INVALID_ARGS", message: "Path and volume required", details: nil))
            return
        }
        
        fmodManager?.setVolume(path: path, volume: Float(volume))
        result(nil)
    }
}

