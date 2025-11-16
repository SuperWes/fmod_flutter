package com.gravesweeper.fmod_flutter

import android.content.Context
import android.util.Log
import org.fmod.FMOD

/**
 * Manages FMOD Studio system and event instances.
 * 
 * Note: This implementation requires FMOD Studio library files to be present:
 * - fmod.jar in android/app/libs/
 * - Native .so files in android/app/src/main/jniLibs/
 */
class FmodManager(private val context: Context) {
    private var studioSystem: org.fmod.studio.System? = null
    private val eventInstances = mutableMapOf<String, org.fmod.studio.EventInstance>()
    
    companion object {
        private const val TAG = "FmodManager"
    }
    
    /**
     * Initialize the FMOD Studio system.
     * @return true if initialization was successful
     */
    fun initialize(): Boolean {
        return try {
            // Initialize FMOD with Android context
            FMOD.init(context)
            
            // Create FMOD Studio system
            studioSystem = org.fmod.studio.System.create()
            
            // Initialize with 512 virtual channels
            studioSystem?.initialize(
                512,
                org.fmod.studio.INITFLAGS.NORMAL,
                org.fmod.core.INITFLAGS.NORMAL,
                null
            )
            
            Log.d(TAG, "FMOD initialized successfully")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize FMOD", e)
            false
        }
    }
    
    /**
     * Load FMOD banks from asset paths.
     * @param bankPaths List of asset paths to FMOD bank files
     * @return true if all banks loaded successfully
     */
    fun loadBanks(bankPaths: List<String>): Boolean {
        return try {
            for (path in bankPaths) {
                loadBank(path)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load banks", e)
            false
        }
    }
    
    /**
     * Load a single FMOD bank from assets.
     */
    private fun loadBank(assetPath: String) {
        val inputStream = context.assets.open(assetPath)
        val bytes = inputStream.readBytes()
        inputStream.close()
        
        studioSystem?.loadBankMemory(
            bytes,
            org.fmod.studio.LOAD_BANK_FLAGS.NORMAL
        )
        
        Log.d(TAG, "Loaded bank: $assetPath")
    }
    
    /**
     * Play an FMOD event by path.
     * @param path Event path (e.g., "event:/Music/MainTheme")
     */
    fun playEvent(path: String) {
        try {
            val eventDescription = studioSystem?.getEvent(path)
            val instance = eventDescription?.createInstance()
            instance?.start()
            
            // Store instance for later control
            instance?.let { eventInstances[path] = it }
            
            Log.d(TAG, "Playing event: $path")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play event: $path", e)
        }
    }
    
    /**
     * Stop a playing event.
     * @param path Event path
     */
    fun stopEvent(path: String) {
        try {
            eventInstances[path]?.stop(org.fmod.studio.STOP_MODE.ALLOWFADEOUT)
            eventInstances.remove(path)
            Log.d(TAG, "Stopped event: $path")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop event: $path", e)
        }
    }
    
    /**
     * Set a parameter value on an event.
     * @param path Event path
     * @param paramName Parameter name
     * @param value Parameter value
     */
    fun setParameter(path: String, paramName: String, value: Float) {
        try {
            eventInstances[path]?.setParameterByName(paramName, value)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set parameter on $path", e)
        }
    }
    
    /**
     * Pause or resume an event.
     * @param path Event path
     * @param paused Whether to pause (true) or resume (false)
     */
    fun setPaused(path: String, paused: Boolean) {
        try {
            eventInstances[path]?.setPaused(paused)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set paused state on $path", e)
        }
    }
    
    /**
     * Set the volume of an event.
     * @param path Event path
     * @param volume Volume (0.0 to 1.0)
     */
    fun setVolume(path: String, volume: Float) {
        try {
            eventInstances[path]?.setVolume(volume)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set volume on $path", e)
        }
    }
    
    /**
     * Update the FMOD system.
     * Should be called regularly (e.g., once per frame).
     */
    fun update() {
        studioSystem?.update()
    }
    
    /**
     * Release all FMOD resources.
     * Should be called when done using FMOD.
     */
    fun release() {
        try {
            // Stop and release all event instances
            eventInstances.values.forEach { it.release() }
            eventInstances.clear()
            
            // Release FMOD system
            studioSystem?.release()
            studioSystem = null
            
            Log.d(TAG, "FMOD released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release FMOD", e)
        }
    }
}

