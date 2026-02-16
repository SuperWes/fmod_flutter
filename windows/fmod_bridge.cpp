#include "fmod_bridge.h"

#include <iostream>
#include <chrono>

namespace fmod_flutter {

FmodBridge::FmodBridge() : studio_system_(nullptr), core_system_(nullptr), running_(false) {}

FmodBridge::~FmodBridge() {
  Release();
}

bool FmodBridge::Initialize() {
  FMOD_RESULT result;

  // Create FMOD Studio System
  result = FMOD_Studio_System_Create(&studio_system_, FMOD_VERSION);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to create FMOD Studio System: "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  // Get the Core System
  result = FMOD_Studio_System_GetCoreSystem(studio_system_, &core_system_);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to get Core System: "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  // Set output type to auto-detect
  result = FMOD_System_SetOutput(core_system_, FMOD_OUTPUTTYPE_AUTODETECT);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Warning - failed to set output type: "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
  }

  // Initialize FMOD Studio System
  result = FMOD_Studio_System_Initialize(studio_system_, 512,
                                         FMOD_STUDIO_INIT_NORMAL,
                                         FMOD_INIT_NORMAL, nullptr);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to initialize FMOD Studio System: "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  // Set master volume to maximum
  FMOD_STUDIO_BUS* master_bus = nullptr;
  result = FMOD_Studio_System_GetBus(studio_system_, "bus:/", &master_bus);
  if (result == FMOD_OK && master_bus != nullptr) {
    FMOD_Studio_Bus_SetVolume(master_bus, 1.0f);
  }

  std::cout << "FmodBridge: FMOD initialized successfully (Windows)" << std::endl;

  // Start background update thread (~60fps), matching iOS behavior
  running_ = true;
  update_thread_ = std::thread(&FmodBridge::UpdateLoop, this);

  return true;
}

bool FmodBridge::LoadBank(const std::string& path) {
  if (studio_system_ == nullptr) {
    std::cerr << "FmodBridge: Studio system not initialized" << std::endl;
    return false;
  }

  FMOD_STUDIO_BANK* bank = nullptr;
  FMOD_RESULT result = FMOD_Studio_System_LoadBankFile(
      studio_system_, path.c_str(), FMOD_STUDIO_LOAD_BANK_NORMAL, &bank);

  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to load bank " << path << ": "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  std::cout << "FmodBridge: Loaded bank: " << path << std::endl;
  return true;
}

bool FmodBridge::PlayEvent(const std::string& event_path) {
  if (studio_system_ == nullptr) {
    std::cerr << "FmodBridge: Studio system not initialized" << std::endl;
    return false;
  }

  FMOD_RESULT result;

  // Get the event description
  FMOD_STUDIO_EVENTDESCRIPTION* event_description = nullptr;
  result = FMOD_Studio_System_GetEvent(studio_system_, event_path.c_str(),
                                       &event_description);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to get event " << event_path << ": "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  // Check if an instance is already playing for this event
  auto it = event_instances_.find(event_path);
  if (it != event_instances_.end()) {
    FMOD_STUDIO_PLAYBACK_STATE state;
    FMOD_Studio_EventInstance_GetPlaybackState(it->second, &state);

    if (state == FMOD_STUDIO_PLAYBACK_PLAYING ||
        state == FMOD_STUDIO_PLAYBACK_STARTING) {
      std::cout << "FmodBridge: Restarting already playing event: "
                << event_path << std::endl;
      FMOD_Studio_EventInstance_Stop(it->second, FMOD_STUDIO_STOP_IMMEDIATE);
      FMOD_Studio_EventInstance_Start(it->second);
      return true;
    } else {
      FMOD_Studio_EventInstance_Release(it->second);
      event_instances_.erase(it);
    }
  }

  // Create an instance of the event
  FMOD_STUDIO_EVENTINSTANCE* event_instance = nullptr;
  result = FMOD_Studio_EventDescription_CreateInstance(event_description,
                                                       &event_instance);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to create event instance for "
              << event_path << ": " << result << " - "
              << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  // Start the event
  result = FMOD_Studio_EventInstance_Start(event_instance);
  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to start event " << event_path << ": "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    FMOD_Studio_EventInstance_Release(event_instance);
    return false;
  }

  // Store the instance for later control
  event_instances_[event_path] = event_instance;
  std::cout << "FmodBridge: Started playing event: " << event_path << std::endl;

  return true;
}

bool FmodBridge::StopEvent(const std::string& event_path) {
  auto it = event_instances_.find(event_path);
  if (it == event_instances_.end()) {
    std::cerr << "FmodBridge: No instance found for " << event_path << std::endl;
    return false;
  }

  FMOD_RESULT result = FMOD_Studio_EventInstance_Stop(
      it->second, FMOD_STUDIO_STOP_ALLOWFADEOUT);

  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to stop event " << event_path << ": "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  FMOD_Studio_EventInstance_Release(it->second);
  event_instances_.erase(it);

  std::cout << "FmodBridge: Stopped event: " << event_path << std::endl;
  return true;
}

bool FmodBridge::SetParameter(const std::string& event_path,
                              const std::string& param_name, float value) {
  auto it = event_instances_.find(event_path);
  if (it == event_instances_.end()) {
    std::cerr << "FmodBridge: No instance found for " << event_path << std::endl;
    return false;
  }

  FMOD_RESULT result = FMOD_Studio_EventInstance_SetParameterByName(
      it->second, param_name.c_str(), value, false);

  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to set parameter " << param_name
              << " on " << event_path << ": " << result << " - "
              << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  return true;
}

bool FmodBridge::SetPaused(const std::string& event_path, bool paused) {
  auto it = event_instances_.find(event_path);
  if (it == event_instances_.end()) {
    std::cerr << "FmodBridge: No instance found for " << event_path << std::endl;
    return false;
  }

  FMOD_RESULT result = FMOD_Studio_EventInstance_SetPaused(
      it->second, paused ? 1 : 0);

  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to set paused state on " << event_path
              << ": " << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  return true;
}

bool FmodBridge::SetVolume(const std::string& event_path, float volume) {
  auto it = event_instances_.find(event_path);
  if (it == event_instances_.end()) {
    std::cerr << "FmodBridge: No instance found for " << event_path << std::endl;
    return false;
  }

  FMOD_RESULT result = FMOD_Studio_EventInstance_SetVolume(it->second, volume);

  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to set volume on " << event_path << ": "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  return true;
}

bool FmodBridge::SetMasterPaused(bool paused) {
  if (studio_system_ == nullptr) {
    std::cerr << "FmodBridge: Studio system not initialized" << std::endl;
    return false;
  }

  FMOD_STUDIO_BUS* master_bus = nullptr;
  FMOD_RESULT result = FMOD_Studio_System_GetBus(studio_system_, "bus:/",
                                                  &master_bus);

  if (result != FMOD_OK || master_bus == nullptr) {
    std::cerr << "FmodBridge: Failed to get master bus: "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  result = FMOD_Studio_Bus_SetPaused(master_bus, paused ? 1 : 0);

  if (result != FMOD_OK) {
    std::cerr << "FmodBridge: Failed to set master paused state: "
              << result << " - " << FMOD_ErrorString(result) << std::endl;
    return false;
  }

  std::cout << "FmodBridge: Master bus paused = "
            << (paused ? "YES" : "NO") << std::endl;
  return true;
}

void FmodBridge::Update() {
  if (studio_system_ != nullptr) {
    FMOD_Studio_System_Update(studio_system_);
  }
}

void FmodBridge::Release() {
  // Stop the update thread
  running_ = false;
  if (update_thread_.joinable()) {
    update_thread_.join();
  }

  // Stop and release all event instances
  for (auto& pair : event_instances_) {
    FMOD_Studio_EventInstance_Stop(pair.second, FMOD_STUDIO_STOP_IMMEDIATE);
    FMOD_Studio_EventInstance_Release(pair.second);
  }
  event_instances_.clear();

  // Release FMOD Studio system
  if (studio_system_ != nullptr) {
    FMOD_Studio_System_Release(studio_system_);
    studio_system_ = nullptr;
    core_system_ = nullptr;
  }

  std::cout << "FmodBridge: Released FMOD resources" << std::endl;
}

void FmodBridge::UpdateLoop() {
  while (running_) {
    if (studio_system_ != nullptr) {
      FMOD_Studio_System_Update(studio_system_);
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
  }
}

}  // namespace fmod_flutter
