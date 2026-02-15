#ifndef FMOD_BRIDGE_H_
#define FMOD_BRIDGE_H_

#include <string>
#include <unordered_map>

#include <fmod_studio.h>
#include <fmod.h>
#include <fmod_errors.h>

namespace fmod_flutter {

class FmodBridge {
 public:
  FmodBridge();
  ~FmodBridge();

  bool Initialize();
  bool LoadBank(const std::string& path);
  bool PlayEvent(const std::string& event_path);
  bool StopEvent(const std::string& event_path);
  bool SetParameter(const std::string& event_path, const std::string& param_name, float value);
  bool SetPaused(const std::string& event_path, bool paused);
  bool SetVolume(const std::string& event_path, float volume);
  bool SetMasterPaused(bool paused);
  void Update();
  void Release();

 private:
  FMOD_STUDIO_SYSTEM* studio_system_;
  FMOD_SYSTEM* core_system_;
  std::unordered_map<std::string, FMOD_STUDIO_EVENTINSTANCE*> event_instances_;
};

}  // namespace fmod_flutter

#endif  // FMOD_BRIDGE_H_
