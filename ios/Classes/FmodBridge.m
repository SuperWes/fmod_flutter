//
//  FmodBridge.m
//  fmod_flutter
//
//  Objective-C bridge to FMOD C API
//

#import "FmodBridge.h"
#import <fmod.h>
#import <fmod_studio.h>
#import <fmod_errors.h>
#import <AVFoundation/AVFoundation.h>

@implementation FmodBridge {
    FMOD_STUDIO_SYSTEM *studioSystem;
    FMOD_SYSTEM *coreSystem;
    NSMutableDictionary<NSString *, NSValue *> *eventInstances;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        studioSystem = NULL;
        coreSystem = NULL;
        eventInstances = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)initializeFmod {
    FMOD_RESULT result;
    
    // Configure iOS Audio Session first
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // Set audio session category to allow playback and mixing with other apps
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&error];
    
    if (error) {
        NSLog(@"FmodBridge: Failed to set audio session category: %@", error);
    }
    
    // Activate the audio session
    [audioSession setActive:YES error:&error];
    
    if (error) {
        NSLog(@"FmodBridge: Failed to activate audio session: %@", error);
    }
    
    // Create FMOD Studio System
    result = FMOD_Studio_System_Create(&studioSystem, FMOD_VERSION);
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to create FMOD Studio System: %d - %s", 
              result, FMOD_ErrorString(result));
        return NO;
    }
    
    // Get the Core System
    result = FMOD_Studio_System_GetCoreSystem(studioSystem, &coreSystem);
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to get Core System: %d - %s", 
              result, FMOD_ErrorString(result));
        return NO;
    }
    
    // Set output type to auto-detect (let FMOD choose best for iOS)
    result = FMOD_System_SetOutput(coreSystem, FMOD_OUTPUTTYPE_AUTODETECT);
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Warning - failed to set output type: %d - %s", 
              result, FMOD_ErrorString(result));
    }
    
    // Initialize FMOD Studio System
    result = FMOD_Studio_System_Initialize(studioSystem, 512, 
                                          FMOD_STUDIO_INIT_NORMAL,
                                          FMOD_INIT_NORMAL, NULL);
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to initialize FMOD Studio System: %d - %s", 
              result, FMOD_ErrorString(result));
        return NO;
    }
    
    // Set master volume to maximum
    FMOD_STUDIO_BUS *masterBus = NULL;
    result = FMOD_Studio_System_GetBus(studioSystem, "bus:/", &masterBus);
    if (result == FMOD_OK && masterBus != NULL) {
        FMOD_Studio_Bus_SetVolume(masterBus, 1.0f);
    }
    
    NSLog(@"FmodBridge: FMOD initialized successfully");
    return YES;
}

- (BOOL)loadBankAtPath:(NSString *)path {
    if (studioSystem == NULL) {
        NSLog(@"FmodBridge: Studio system not initialized");
        return NO;
    }
    
    FMOD_STUDIO_BANK *bank = NULL;
    FMOD_RESULT result = FMOD_Studio_System_LoadBankFile(studioSystem, 
                                                         [path UTF8String],
                                                         FMOD_STUDIO_LOAD_BANK_NORMAL,
                                                         &bank);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to load bank %@: %d - %s", 
              path, result, FMOD_ErrorString(result));
        return NO;
    }
    
    NSLog(@"FmodBridge: Loaded bank: %@", path);
    return YES;
}

- (BOOL)playEvent:(NSString *)eventPath {
    if (studioSystem == NULL) {
        NSLog(@"FmodBridge: Studio system not initialized");
        return NO;
    }
    
    FMOD_RESULT result;
    
    // Get the event description
    FMOD_STUDIO_EVENTDESCRIPTION *eventDescription = NULL;
    result = FMOD_Studio_System_GetEvent(studioSystem, 
                                        [eventPath UTF8String],
                                        &eventDescription);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to get event %@: %d - %s", 
              eventPath, result, FMOD_ErrorString(result));
        return NO;
    }
    
    // Check if an instance is already playing for this event
    NSValue *existingValue = eventInstances[eventPath];
    if (existingValue != nil) {
        FMOD_STUDIO_EVENTINSTANCE *existingInstance = [existingValue pointerValue];
        FMOD_STUDIO_PLAYBACK_STATE state;
        FMOD_Studio_EventInstance_GetPlaybackState(existingInstance, &state);
        
        // If still playing, restart it
        if (state == FMOD_STUDIO_PLAYBACK_PLAYING || 
            state == FMOD_STUDIO_PLAYBACK_STARTING) {
            NSLog(@"FmodBridge: Restarting already playing event: %@", eventPath);
            FMOD_Studio_EventInstance_Stop(existingInstance, FMOD_STUDIO_STOP_IMMEDIATE);
            FMOD_Studio_EventInstance_Start(existingInstance);
            return YES;
        } else {
            // Release the old stopped instance
            FMOD_Studio_EventInstance_Release(existingInstance);
            [eventInstances removeObjectForKey:eventPath];
        }
    }
    
    // Create an instance of the event
    FMOD_STUDIO_EVENTINSTANCE *eventInstance = NULL;
    result = FMOD_Studio_EventDescription_CreateInstance(eventDescription, 
                                                        &eventInstance);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to create event instance for %@: %d - %s", 
              eventPath, result, FMOD_ErrorString(result));
        return NO;
    }
    
    // Start the event
    result = FMOD_Studio_EventInstance_Start(eventInstance);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to start event %@: %d - %s", 
              eventPath, result, FMOD_ErrorString(result));
        FMOD_Studio_EventInstance_Release(eventInstance);
        return NO;
    }
    
    // Store the instance for later control
    eventInstances[eventPath] = [NSValue valueWithPointer:eventInstance];
    NSLog(@"FmodBridge: Started playing event: %@", eventPath);
    
    return YES;
}

- (BOOL)stopEvent:(NSString *)eventPath {
    NSValue *instanceValue = eventInstances[eventPath];
    if (instanceValue == nil) {
        NSLog(@"FmodBridge: No instance found for %@", eventPath);
        return NO;
    }
    
    FMOD_STUDIO_EVENTINSTANCE *eventInstance = [instanceValue pointerValue];
    
    // Stop the event with fade out
    FMOD_RESULT result = FMOD_Studio_EventInstance_Stop(eventInstance, 
                                                        FMOD_STUDIO_STOP_ALLOWFADEOUT);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to stop event %@: %d - %s", 
              eventPath, result, FMOD_ErrorString(result));
        return NO;
    }
    
    // Release the instance
    FMOD_Studio_EventInstance_Release(eventInstance);
    [eventInstances removeObjectForKey:eventPath];
    
    NSLog(@"FmodBridge: Stopped event: %@", eventPath);
    return YES;
}

- (BOOL)setParameterForEvent:(NSString *)eventPath
                   paramName:(NSString *)paramName
                       value:(float)value {
    NSValue *instanceValue = eventInstances[eventPath];
    if (instanceValue == nil) {
        NSLog(@"FmodBridge: No instance found for %@", eventPath);
        return NO;
    }
    
    FMOD_STUDIO_EVENTINSTANCE *eventInstance = [instanceValue pointerValue];
    
    FMOD_RESULT result = FMOD_Studio_EventInstance_SetParameterByName(eventInstance,
                                                                      [paramName UTF8String],
                                                                      value,
                                                                      false);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to set parameter %@ on %@: %d - %s", 
              paramName, eventPath, result, FMOD_ErrorString(result));
        return NO;
    }
    
    return YES;
}

- (BOOL)setPausedForEvent:(NSString *)eventPath paused:(BOOL)paused {
    NSValue *instanceValue = eventInstances[eventPath];
    if (instanceValue == nil) {
        NSLog(@"FmodBridge: No instance found for %@", eventPath);
        return NO;
    }
    
    FMOD_STUDIO_EVENTINSTANCE *eventInstance = [instanceValue pointerValue];
    
    FMOD_RESULT result = FMOD_Studio_EventInstance_SetPaused(eventInstance, 
                                                            paused ? 1 : 0);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to set paused state on %@: %d - %s", 
              eventPath, result, FMOD_ErrorString(result));
        return NO;
    }
    
    return YES;
}

- (BOOL)setVolumeForEvent:(NSString *)eventPath volume:(float)volume {
    NSValue *instanceValue = eventInstances[eventPath];
    if (instanceValue == nil) {
        NSLog(@"FmodBridge: No instance found for %@", eventPath);
        return NO;
    }
    
    FMOD_STUDIO_EVENTINSTANCE *eventInstance = [instanceValue pointerValue];
    
    FMOD_RESULT result = FMOD_Studio_EventInstance_SetVolume(eventInstance, volume);
    
    if (result != FMOD_OK) {
        NSLog(@"FmodBridge: Failed to set volume on %@: %d - %s", 
              eventPath, result, FMOD_ErrorString(result));
        return NO;
    }
    
    return YES;
}

- (void)update {
    if (studioSystem != NULL) {
        FMOD_Studio_System_Update(studioSystem);
    }
}

- (void)releaseFmod {
    // Stop and release all event instances
    for (NSString *key in eventInstances) {
        FMOD_STUDIO_EVENTINSTANCE *instance = [eventInstances[key] pointerValue];
        FMOD_Studio_EventInstance_Stop(instance, FMOD_STUDIO_STOP_IMMEDIATE);
        FMOD_Studio_EventInstance_Release(instance);
    }
    [eventInstances removeAllObjects];
    
    // Release FMOD Studio system
    if (studioSystem != NULL) {
        FMOD_Studio_System_Release(studioSystem);
        studioSystem = NULL;
        coreSystem = NULL;
    }
    
    NSLog(@"FmodBridge: Released FMOD resources");
}

- (void)logAvailableEvents {
    if (studioSystem == NULL) {
        return;
    }
    
    // Get bank count
    int bankCount = 0;
    FMOD_Studio_System_GetBankCount(studioSystem, &bankCount);
    
    if (bankCount == 0) {
        return;
    }
    
    NSLog(@"FmodBridge: Available FMOD events:");
    
    // Iterate through banks
    FMOD_STUDIO_BANK *banks[bankCount];
    int actualCount = 0;
    FMOD_Studio_System_GetBankList(studioSystem, banks, bankCount, &actualCount);
    
    for (int i = 0; i < actualCount; i++) {
        // Get event count in this bank
        int eventCount = 0;
        FMOD_Studio_Bank_GetEventCount(banks[i], &eventCount);
        
        if (eventCount > 0) {
            FMOD_STUDIO_EVENTDESCRIPTION *events[eventCount];
            int actualEventCount = 0;
            FMOD_Studio_Bank_GetEventList(banks[i], events, eventCount, &actualEventCount);
            
            for (int j = 0; j < actualEventCount; j++) {
                char eventPath[512];
                FMOD_Studio_EventDescription_GetPath(events[j], eventPath, 512, NULL);
                NSLog(@"  - %s", eventPath);
            }
        }
    }
}

- (void)dealloc {
    [self releaseFmod];
}

@end

