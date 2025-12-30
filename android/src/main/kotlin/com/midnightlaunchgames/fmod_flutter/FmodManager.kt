package com.midnightlaunchgames.fmod_flutter

import android.content.Context
import android.content.res.AssetManager
import android.util.Log
import android.os.Handler
import android.os.Looper
import java.io.IOException

/**
 * FMOD Manager for Android with JNI integration.
 * 
 * Provides Kotlin API for FMOD Studio, backed by native C++ implementation.
 */
class FmodManager(private val context: Context) {
    
    companion object {
        private const val TAG = "FmodManager"
        
        // Load native library
        init {
            System.loadLibrary("fmod")
            System.loadLibrary("fmodstudio")
            System.loadLibrary("fmod_flutter")
        }
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private val updateRunnable = object : Runnable {
        override fun run() {
            nativeUpdate()
            handler.postDelayed(this, 16) // ~60 FPS
        }
    }
    
    // Native methods
    private external fun nativeInitialize(): Boolean
    private external fun nativeLoadBank(bankData: ByteArray): Boolean
    private external fun nativePlayEvent(eventPath: String): Boolean
    private external fun nativeStopEvent(eventPath: String): Boolean
    private external fun nativeSetParameter(eventPath: String, paramName: String, value: Float): Boolean
    private external fun nativeSetPaused(eventPath: String, paused: Boolean): Boolean
    private external fun nativeSetVolume(eventPath: String, volume: Float): Boolean
    private external fun nativeUpdate()
    private external fun nativeRelease()
    private external fun nativeLogAvailableEvents()
    
    /**
     * Initialize the FMOD Studio system.
     * @return true if successful
     */
    fun initialize(): Boolean {
        Log.d(TAG, "Initializing FMOD...")
        
        val success = nativeInitialize()
        
        if (success) {
            Log.d(TAG, "FMOD initialized successfully")
            // Start update loop
            handler.post(updateRunnable)
        } else {
            Log.e(TAG, "Failed to initialize FMOD")
        }
        
        return success
    }
    
    /**
     * Load FMOD banks from asset paths.
     * @param bankPaths List of asset paths to FMOD bank files
     * @return true if all banks loaded successfully
     */
    fun loadBanks(bankPaths: List<String>): Boolean {
        Log.d(TAG, "Loading ${bankPaths.size} banks...")
        
        var allLoaded = true
        val assetManager = context.assets
        
        for (bankPath in bankPaths) {
            try {
                // Flutter assets are stored in flutter_assets/ subdirectory on Android
                val flutterAssetPath = "flutter_assets/$bankPath"
                
                // Read bank file from assets
                val inputStream = try {
                    assetManager.open(flutterAssetPath)
                } catch (e: IOException) {
                    // Fallback to direct path if flutter_assets prefix doesn't work
                    Log.d(TAG, "Trying fallback path: $bankPath")
                    assetManager.open(bankPath)
                }
                val bankData = inputStream.readBytes()
                inputStream.close()
                
                Log.d(TAG, "Loading bank: $flutterAssetPath (${bankData.size} bytes)")
                
                if (nativeLoadBank(bankData)) {
                    Log.d(TAG, "✓ Loaded: $flutterAssetPath")
                } else {
                    Log.e(TAG, "✗ Failed to load: $flutterAssetPath")
                    allLoaded = false
                }
            } catch (e: IOException) {
                Log.e(TAG, "Failed to read bank file: $bankPath (tried flutter_assets/$bankPath)", e)
                allLoaded = false
            }
        }
        
        if (allLoaded) {
            // Log available events for debugging
            nativeLogAvailableEvents()
        }
        
        return allLoaded
    }
    
    /**
     * Play an FMOD event by path.
     * @param path Event path (e.g., "event:/Music/MainTheme")
     */
    fun playEvent(path: String) {
        Log.d(TAG, "Playing event: $path")
        if (!nativePlayEvent(path)) {
            Log.e(TAG, "Failed to play event: $path")
        }
    }
    
    /**
     * Stop a playing event.
     * @param path Event path
     */
    fun stopEvent(path: String) {
        Log.d(TAG, "Stopping event: $path")
        if (!nativeStopEvent(path)) {
            Log.e(TAG, "Failed to stop event: $path")
        }
    }
    
    /**
     * Set a parameter value on an event.
     * @param path Event path
     * @param paramName Parameter name
     * @param value Parameter value
     */
    fun setParameter(path: String, paramName: String, value: Float) {
        if (!nativeSetParameter(path, paramName, value)) {
            Log.e(TAG, "Failed to set parameter $paramName for event: $path")
        }
    }
    
    /**
     * Pause or resume an event.
     * @param path Event path
     * @param paused Whether to pause (true) or resume (false)
     */
    fun setPaused(path: String, paused: Boolean) {
        if (!nativeSetPaused(path, paused)) {
            Log.e(TAG, "Failed to set paused state for event: $path")
        }
    }
    
    /**
     * Set the volume of an event.
     * @param path Event path
     * @param volume Volume (0.0 to 1.0)
     */
    fun setVolume(path: String, volume: Float) {
        if (!nativeSetVolume(path, volume)) {
            Log.e(TAG, "Failed to set volume for event: $path")
        }
    }
    
    /**
     * Update the FMOD system.
     * Should be called regularly (e.g., once per frame).
     * This is called automatically by the update loop.
     */
    fun update() {
        nativeUpdate()
    }
    
    /**
     * Release all FMOD resources.
     * Should be called when done using FMOD.
     */
    fun release() {
        Log.d(TAG, "Releasing FMOD...")
        handler.removeCallbacks(updateRunnable)
        nativeRelease()
    }
}
