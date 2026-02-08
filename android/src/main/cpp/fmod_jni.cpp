#include <jni.h>
#include <android/log.h>
#include <string>
#include <map>
#include <fmod.hpp>
#include <fmod_studio.hpp>
#include <fmod_errors.h>

#define LOG_TAG "FmodJNI"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global FMOD system pointers
static FMOD::Studio::System* studioSystem = nullptr;
static FMOD::System* coreSystem = nullptr;

// Map to track event instances by path
static std::map<std::string, FMOD::Studio::EventInstance*> eventInstances;

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeInitialize(
    JNIEnv* env, jobject thiz) {
    
    FMOD_RESULT result;
    
    // Create FMOD Studio System
    result = FMOD::Studio::System::create(&studioSystem);
    if (result != FMOD_OK) {
        LOGE("Failed to create FMOD Studio System: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    // Get Core System
    result = studioSystem->getCoreSystem(&coreSystem);
    if (result != FMOD_OK) {
        LOGE("Failed to get Core System: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    // Initialize with 512 channels
    result = studioSystem->initialize(
        512,
        FMOD_STUDIO_INIT_NORMAL,
        FMOD_INIT_NORMAL,
        nullptr
    );
    
    if (result != FMOD_OK) {
        LOGE("Failed to initialize FMOD Studio System: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    // Set master bus volume
    FMOD::Studio::Bus* masterBus = nullptr;
    result = studioSystem->getBus("bus:/", &masterBus);
    if (result == FMOD_OK && masterBus != nullptr) {
        masterBus->setVolume(1.0f);
    }
    
    LOGD("FMOD initialized successfully");
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeLoadBank(
    JNIEnv* env, jobject thiz, jbyteArray bankData) {
    
    if (studioSystem == nullptr) {
        LOGE("FMOD Studio System not initialized");
        return JNI_FALSE;
    }
    
    // Get bank data from Java byte array
    jsize dataSize = env->GetArrayLength(bankData);
    jbyte* data = env->GetByteArrayElements(bankData, nullptr);
    
    FMOD::Studio::Bank* bank = nullptr;
    FMOD_RESULT result = studioSystem->loadBankMemory(
        (const char*)data,
        dataSize,
        FMOD_STUDIO_LOAD_MEMORY,
        FMOD_STUDIO_LOAD_BANK_NORMAL,
        &bank
    );
    
    env->ReleaseByteArrayElements(bankData, data, JNI_ABORT);
    
    if (result != FMOD_OK) {
        LOGE("Failed to load bank: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    LOGD("Bank loaded successfully");
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativePlayEvent(
    JNIEnv* env, jobject thiz, jstring eventPath) {
    
    if (studioSystem == nullptr) {
        LOGE("FMOD Studio System not initialized");
        return JNI_FALSE;
    }
    
    const char* pathStr = env->GetStringUTFChars(eventPath, nullptr);
    std::string path(pathStr);
    env->ReleaseStringUTFChars(eventPath, pathStr);
    
    // Check if event already has an instance
    auto it = eventInstances.find(path);
    if (it != eventInstances.end()) {
        // Stop existing instance
        it->second->stop(FMOD_STUDIO_STOP_IMMEDIATE);
        it->second->release();
        eventInstances.erase(it);
    }
    
    // Get event description
    FMOD::Studio::EventDescription* eventDesc = nullptr;
    FMOD_RESULT result = studioSystem->getEvent(path.c_str(), &eventDesc);
    if (result != FMOD_OK) {
        LOGE("Failed to get event %s: %d - %s", path.c_str(), result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    // Create instance
    FMOD::Studio::EventInstance* eventInstance = nullptr;
    result = eventDesc->createInstance(&eventInstance);
    if (result != FMOD_OK) {
        LOGE("Failed to create event instance: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    // Start the event
    result = eventInstance->start();
    if (result != FMOD_OK) {
        LOGE("Failed to start event: %d - %s", result, FMOD_ErrorString(result));
        eventInstance->release();
        return JNI_FALSE;
    }
    
    // Store the instance
    eventInstances[path] = eventInstance;
    
    LOGD("Playing event: %s", path.c_str());
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeStopEvent(
    JNIEnv* env, jobject thiz, jstring eventPath) {
    
    const char* pathStr = env->GetStringUTFChars(eventPath, nullptr);
    std::string path(pathStr);
    env->ReleaseStringUTFChars(eventPath, pathStr);
    
    auto it = eventInstances.find(path);
    if (it == eventInstances.end()) {
        LOGD("No instance found for event: %s", path.c_str());
        return JNI_FALSE;
    }
    
    FMOD_RESULT result = it->second->stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
    if (result != FMOD_OK) {
        LOGE("Failed to stop event: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    it->second->release();
    eventInstances.erase(it);
    
    LOGD("Stopped event: %s", path.c_str());
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeSetParameter(
    JNIEnv* env, jobject thiz, jstring eventPath, jstring paramName, jfloat value) {
    
    const char* pathStr = env->GetStringUTFChars(eventPath, nullptr);
    std::string path(pathStr);
    env->ReleaseStringUTFChars(eventPath, pathStr);
    
    const char* paramStr = env->GetStringUTFChars(paramName, nullptr);
    std::string param(paramStr);
    env->ReleaseStringUTFChars(paramName, paramStr);
    
    auto it = eventInstances.find(path);
    if (it == eventInstances.end()) {
        LOGD("No instance found for event: %s", path.c_str());
        return JNI_FALSE;
    }
    
    FMOD_RESULT result = it->second->setParameterByName(param.c_str(), value);
    if (result != FMOD_OK) {
        LOGE("Failed to set parameter: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    LOGD("Set parameter %s = %f for event: %s", param.c_str(), value, path.c_str());
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeSetPaused(
    JNIEnv* env, jobject thiz, jstring eventPath, jboolean paused) {
    
    const char* pathStr = env->GetStringUTFChars(eventPath, nullptr);
    std::string path(pathStr);
    env->ReleaseStringUTFChars(eventPath, pathStr);
    
    auto it = eventInstances.find(path);
    if (it == eventInstances.end()) {
        LOGD("No instance found for event: %s", path.c_str());
        return JNI_FALSE;
    }
    
    FMOD_RESULT result = it->second->setPaused(paused == JNI_TRUE);
    if (result != FMOD_OK) {
        LOGE("Failed to set paused state: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    LOGD("Set paused = %d for event: %s", paused, path.c_str());
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeSetVolume(
    JNIEnv* env, jobject thiz, jstring eventPath, jfloat volume) {
    
    const char* pathStr = env->GetStringUTFChars(eventPath, nullptr);
    std::string path(pathStr);
    env->ReleaseStringUTFChars(eventPath, pathStr);
    
    auto it = eventInstances.find(path);
    if (it == eventInstances.end()) {
        LOGD("No instance found for event: %s", path.c_str());
        return JNI_FALSE;
    }
    
    FMOD_RESULT result = it->second->setVolume(volume);
    if (result != FMOD_OK) {
        LOGE("Failed to set volume: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    LOGD("Set volume = %f for event: %s", volume, path.c_str());
    return JNI_TRUE;
}

JNIEXPORT void JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeUpdate(
    JNIEnv* env, jobject thiz) {
    
    if (studioSystem != nullptr) {
        studioSystem->update();
    }
}

JNIEXPORT void JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeRelease(
    JNIEnv* env, jobject thiz) {
    
    // Release all event instances
    for (auto& pair : eventInstances) {
        pair.second->stop(FMOD_STUDIO_STOP_IMMEDIATE);
        pair.second->release();
    }
    eventInstances.clear();
    
    // Release FMOD Studio System
    if (studioSystem != nullptr) {
        studioSystem->release();
        studioSystem = nullptr;
        coreSystem = nullptr;
    }
    
    LOGD("FMOD released");
}

JNIEXPORT void JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeLogAvailableEvents(
    JNIEnv* env, jobject thiz) {
    
    if (studioSystem == nullptr) {
        LOGE("FMOD Studio System not initialized");
        return;
    }
    
    // Get all banks
    int bankCount = 0;
    studioSystem->getBankCount(&bankCount);
    
    if (bankCount == 0) {
        LOGD("No banks loaded");
        return;
    }
    
    FMOD::Studio::Bank** banks = new FMOD::Studio::Bank*[bankCount];
    studioSystem->getBankList(banks, bankCount, &bankCount);
    
    LOGD("=== Available FMOD Events ===");
    
    for (int i = 0; i < bankCount; i++) {
        int eventCount = 0;
        banks[i]->getEventCount(&eventCount);
        
        if (eventCount > 0) {
            FMOD::Studio::EventDescription** events = new FMOD::Studio::EventDescription*[eventCount];
            banks[i]->getEventList(events, eventCount, &eventCount);
            
            for (int j = 0; j < eventCount; j++) {
                char path[512];
                int pathLen = 0;
                events[j]->getPath(path, 512, &pathLen);
                LOGD("  %s", path);
            }
            
            delete[] events;
        }
    }
    
    delete[] banks;
    LOGD("=============================");
}

JNIEXPORT jboolean JNICALL
Java_com_midnightlaunchgames_fmod_1flutter_FmodManager_nativeSetMasterPaused(
    JNIEnv* env, jobject thiz, jboolean paused) {
    
    if (studioSystem == nullptr) {
        LOGE("FMOD Studio System not initialized");
        return JNI_FALSE;
    }
    
    FMOD::Studio::Bus* masterBus = nullptr;
    FMOD_RESULT result = studioSystem->getBus("bus:/", &masterBus);
    
    if (result != FMOD_OK || masterBus == nullptr) {
        LOGE("Failed to get master bus: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    result = masterBus->setPaused(paused == JNI_TRUE);
    if (result != FMOD_OK) {
        LOGE("Failed to set master paused: %d - %s", result, FMOD_ErrorString(result));
        return JNI_FALSE;
    }
    
    LOGD("Master bus paused = %d", paused);
    return JNI_TRUE;
}

} // extern "C"

