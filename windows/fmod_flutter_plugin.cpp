#include "fmod_flutter_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>

#include <filesystem>
#include <memory>
#include <string>
#include <variant>

namespace fmod_flutter {

// Returns the directory containing the running executable.
static std::filesystem::path GetExecutableDir() {
  wchar_t path_buf[MAX_PATH];
  GetModuleFileNameW(nullptr, path_buf, MAX_PATH);
  return std::filesystem::path(path_buf).parent_path();
}

// Resolves an asset path (e.g. "assets/audio/Master.bank") to an absolute path.
// On Windows Flutter desktop, assets live at <exe_dir>/data/flutter_assets/<asset>.
// Falls back to the raw path if the resolved file doesn't exist (e.g. in debug mode
// where the CWD is the project root and the raw relative path already works).
static std::string ResolveAssetPath(const std::string& asset_path) {
  auto exe_dir = GetExecutableDir();
  auto resolved = exe_dir / "data" / "flutter_assets" / asset_path;
  if (std::filesystem::exists(resolved)) {
    return resolved.string();
  }
  // Fallback: return original path (works in debug when CWD is project root)
  return asset_path;
}

// static
void FmodFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "fmod_flutter",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FmodFlutterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FmodFlutterPlugin::FmodFlutterPlugin()
    : fmod_bridge_(std::make_unique<FmodBridge>()) {}

FmodFlutterPlugin::~FmodFlutterPlugin() {}

void FmodFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method_name = method_call.method_name();

  if (method_name == "initialize") {
    bool success = fmod_bridge_->Initialize();
    result->Success(flutter::EncodableValue(success));

  } else if (method_name == "loadBanks") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("banks"));
      if (it != args->end()) {
        const auto *banks = std::get_if<flutter::EncodableList>(&it->second);
        if (banks) {
          bool all_loaded = true;
          for (const auto &bank : *banks) {
            const auto *bank_path = std::get_if<std::string>(&bank);
            if (bank_path) {
              std::string resolved = ResolveAssetPath(*bank_path);
              if (!fmod_bridge_->LoadBank(resolved)) {
                all_loaded = false;
              }
            }
          }
          result->Success(flutter::EncodableValue(all_loaded));
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Banks list required");

  } else if (method_name == "playEvent") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("path"));
      if (it != args->end()) {
        const auto *path = std::get_if<std::string>(&it->second);
        if (path) {
          fmod_bridge_->PlayEvent(*path);
          result->Success();
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Event path required");

  } else if (method_name == "stopEvent") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("path"));
      if (it != args->end()) {
        const auto *path = std::get_if<std::string>(&it->second);
        if (path) {
          fmod_bridge_->StopEvent(*path);
          result->Success();
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Event path required");

  } else if (method_name == "setParameter") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto path_it = args->find(flutter::EncodableValue("path"));
      auto param_it = args->find(flutter::EncodableValue("parameter"));
      auto value_it = args->find(flutter::EncodableValue("value"));
      if (path_it != args->end() && param_it != args->end() &&
          value_it != args->end()) {
        const auto *path = std::get_if<std::string>(&path_it->second);
        const auto *param = std::get_if<std::string>(&param_it->second);
        const auto *value = std::get_if<double>(&value_it->second);
        if (path && param && value) {
          fmod_bridge_->SetParameter(*path, *param, static_cast<float>(*value));
          result->Success();
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Path, parameter, and value required");

  } else if (method_name == "setPaused") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto path_it = args->find(flutter::EncodableValue("path"));
      auto paused_it = args->find(flutter::EncodableValue("paused"));
      if (path_it != args->end() && paused_it != args->end()) {
        const auto *path = std::get_if<std::string>(&path_it->second);
        const auto *paused = std::get_if<bool>(&paused_it->second);
        if (path && paused) {
          fmod_bridge_->SetPaused(*path, *paused);
          result->Success();
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Path and paused state required");

  } else if (method_name == "setVolume") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto path_it = args->find(flutter::EncodableValue("path"));
      auto volume_it = args->find(flutter::EncodableValue("volume"));
      if (path_it != args->end() && volume_it != args->end()) {
        const auto *path = std::get_if<std::string>(&path_it->second);
        const auto *volume = std::get_if<double>(&volume_it->second);
        if (path && volume) {
          fmod_bridge_->SetVolume(*path, static_cast<float>(*volume));
          result->Success();
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Path and volume required");

  } else if (method_name == "setMasterPaused") {
    const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto paused_it = args->find(flutter::EncodableValue("paused"));
      if (paused_it != args->end()) {
        const auto *paused = std::get_if<bool>(&paused_it->second);
        if (paused) {
          fmod_bridge_->SetMasterPaused(*paused);
          result->Success();
          return;
        }
      }
    }
    result->Error("INVALID_ARGS", "Paused state required");

  } else if (method_name == "update") {
    fmod_bridge_->Update();
    result->Success();

  } else if (method_name == "release") {
    fmod_bridge_->Release();
    result->Success();

  } else {
    result->NotImplemented();
  }
}

}  // namespace fmod_flutter
