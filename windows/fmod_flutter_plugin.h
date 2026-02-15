#ifndef FLUTTER_PLUGIN_FMOD_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_FMOD_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "fmod_bridge.h"

namespace fmod_flutter {

class FmodFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FmodFlutterPlugin();
  virtual ~FmodFlutterPlugin();

  // Disallow copy and assign.
  FmodFlutterPlugin(const FmodFlutterPlugin&) = delete;
  FmodFlutterPlugin& operator=(const FmodFlutterPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<FmodBridge> fmod_bridge_;
};

}  // namespace fmod_flutter

#endif  // FLUTTER_PLUGIN_FMOD_FLUTTER_PLUGIN_H_
