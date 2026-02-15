import Foundation

/**
 * Manages FMOD Studio system and event instances for macOS.
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
            // On macOS, Flutter assets are in the app bundle's Contents/Frameworks/App.framework/Resources/flutter_assets/
            var fullPath: String?
            
            // Try the macOS bundle path
            if let resourcePath = Bundle.main.resourcePath {
                let macPath = "\(resourcePath)/flutter_assets/\(bankPath)"
                if FileManager.default.fileExists(atPath: macPath) {
                    fullPath = macPath
                }
            }
            
            // Try Frameworks/App.framework path
            if fullPath == nil {
                if let frameworksPath = Bundle.main.privateFrameworksPath {
                    let appFrameworkPath = "\(frameworksPath)/App.framework/Resources/flutter_assets/\(bankPath)"
                    if FileManager.default.fileExists(atPath: appFrameworkPath) {
                        fullPath = appFrameworkPath
                    }
                }
            }
            
            // Last resort: try in main bundle directly
            if fullPath == nil {
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
     */
    func setParameter(path: String, paramName: String, value: Float) {
        _ = bridge.setParameterForEvent(path, paramName: paramName, value: value)
    }
    
    /**
     * Pause or resume an event.
     */
    func setPaused(path: String, paused: Bool) {
        _ = bridge.setPausedForEvent(path, paused: paused)
    }
    
    /**
     * Set the volume of an event.
     */
    func setVolume(path: String, volume: Float) {
        _ = bridge.setVolumeForEvent(path, volume: volume)
    }
    
    /**
     * Pause or resume the master bus (all audio).
     */
    func setMasterPaused(_ paused: Bool) {
        _ = bridge.setMasterPaused(paused)
    }
    
    /**
     * Update the FMOD system.
     */
    func update() {
        bridge.update()
    }
    
    /**
     * Release all FMOD resources.
     */
    func release() {
        updateTimer?.invalidate()
        updateTimer = nil
        bridge.releaseFmod()
    }
    
    deinit {
        release()
    }
}
