#include "include/fmod_flutter/fmod_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "fmod_flutter_plugin.h"

void FmodFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  fmod_flutter::FmodFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
