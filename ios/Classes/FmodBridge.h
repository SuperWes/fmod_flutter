//
//  FmodBridge.h
//  fmod_flutter
//
//  Objective-C bridge to FMOD C API
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FmodBridge : NSObject

- (BOOL)initializeFmod;
- (BOOL)loadBankAtPath:(NSString *)path;
- (BOOL)playEvent:(NSString *)eventPath;
- (BOOL)stopEvent:(NSString *)eventPath;
- (BOOL)setParameterForEvent:(NSString *)eventPath
                   paramName:(NSString *)paramName
                       value:(float)value;
- (BOOL)setPausedForEvent:(NSString *)eventPath paused:(BOOL)paused;
- (BOOL)setVolumeForEvent:(NSString *)eventPath volume:(float)volume;
- (void)update;
- (void)releaseFmod;
- (void)logAvailableEvents;
- (BOOL)setMasterPaused:(BOOL)paused;

@end

NS_ASSUME_NONNULL_END

