import Foundation

/**
 * Manages FMOD Studio system and event instances for iOS.
 * Uses FmodBridge (Objective-C) to interface with FMOD C API.
 */
class FmodManager {
    private let bridge = FmodBridge()
    private var updateTimer: Timer?
    
    /**
     * Initialize the FMOD Studio system.
     * @return true if initialization was successful
     */
    func initialize() -> Bool {
        let success = bridge.initializeFmod()
        
        if success {
            // Start update timer to call FMOD update regularly (60 times per second)
            updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
                self?.bridge.update()
            }
        }
        
        return success
    }
    
    /**
     * Load FMOD banks from bundle paths.
     * @param bankPaths List of paths to FMOD bank files in Flutter assets
     * @return true if all banks loaded successfully
     */
    func loadBanks(_ bankPaths: [String]) -> Bool {
        var allLoaded = true
        
        for bankPath in bankPaths {
            // Flutter assets are in Frameworks/App.framework/flutter_assets/
            let flutterAssetsPath = Bundle.main.path(forResource: "Frameworks/App.framework/flutter_assets", ofType: nil)
            
            var fullPath: String?
            
            if let assetsPath = flutterAssetsPath {
                // Try with flutter_assets prefix
                fullPath = "\(assetsPath)/\(bankPath)"
            }
            
            // If not found, try without prefix (the path might already be relative to assets)
            if fullPath == nil || !FileManager.default.fileExists(atPath: fullPath!) {
                // Try as direct path in Flutter.framework
                let appBundle = Bundle.main.path(forResource: "Frameworks/App.framework/flutter_assets/\(bankPath)", ofType: nil)
                fullPath = appBundle
            }
            
            // Last resort: try in main bundle directly
            if fullPath == nil || !FileManager.default.fileExists(atPath: fullPath!) {
                fullPath = Bundle.main.path(forResource: bankPath, ofType: nil)
            }
            
            guard let validPath = fullPath, FileManager.default.fileExists(atPath: validPath) else {
                print("FmodManager: Bank file not found: \(bankPath)")
                allLoaded = false
                continue
            }
            
            if !bridge.loadBank(atPath: validPath) {
                allLoaded = false
            }
        }
        
        // After loading all banks, log what events are available
        bridge.logAvailableEvents()
        
        return allLoaded
    }
    
    /**
     * Play an FMOD event by path.
     * @param path Event path (e.g., "event:/Music/MainTheme")
     */
    func playEvent(_ path: String) {
        let success = bridge.playEvent(path)
        if !success {
            print("FmodManager: Failed to play event: \(path)")
        }
    }
    
    /**
     * Stop a playing event.
     * @param path Event path
     */
    func stopEvent(_ path: String) {
        let success = bridge.stopEvent(path)
        if !success {
            print("FmodManager ERROR: Failed to stop event: \(path)")
        }
    }
    
    /**
     * Set a parameter value on an event.
     * @param path Event path
     * @param paramName Parameter name
     * @param value Parameter value
     */
    func setParameter(path: String, paramName: String, value: Float) {
        _ = bridge.setParameterForEvent(path, paramName: paramName, value: value)
    }
    
    /**
     * Pause or resume an event.
     * @param path Event path
     * @param paused Whether to pause (true) or resume (false)
     */
    func setPaused(path: String, paused: Bool) {
        _ = bridge.setPausedForEvent(path, paused: paused)
    }
    
    /**
     * Set the volume of an event.
     * @param path Event path
     * @param volume Volume (0.0 to 1.0)
     */
    func setVolume(path: String, volume: Float) {
        _ = bridge.setVolumeForEvent(path, volume: volume)
    }
    
    /**
     * Update the FMOD system.
     * Should be called regularly (e.g., once per frame).
     */

    /**
     * Pause or resume the master bus (all audio).
     * @param paused Whether to pause (true) or resume (false)
     */
    func setMasterPaused(_ paused: Bool) {
        _ = bridge.setMasterPaused(paused)
    }

    func update() {
        bridge.update()
    }
    
    /**
     * Release all FMOD resources.
     */
    func release() {
        // Stop the update timer
        updateTimer?.invalidate()
        updateTimer = nil
        
        bridge.releaseFmod()
    }
    
    deinit {
        release()
    }
}
