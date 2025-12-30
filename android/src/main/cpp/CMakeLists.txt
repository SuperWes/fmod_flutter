cmake_minimum_required(VERSION 3.10)

project(fmod_flutter)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find FMOD libraries path
# Search multiple locations for flexibility:
# 1. App's jniLibs (when using setup script with git dependency)
# 2. Plugin's own jniLibs (legacy/alternative setup)

# Try app's jniLibs first (works with git dependency + setup script)
set(APP_JNILIBS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../android/app/src/main/jniLibs/${ANDROID_ABI}")
set(PLUGIN_JNILIBS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}")

if(EXISTS "${APP_JNILIBS_PATH}/libfmod.so")
    set(FMOD_LIB_DIR "${APP_JNILIBS_PATH}")
    message(STATUS "FMOD: Using app's jniLibs at ${FMOD_LIB_DIR}")
elseif(EXISTS "${PLUGIN_JNILIBS_PATH}/libfmod.so")
    set(FMOD_LIB_DIR "${PLUGIN_JNILIBS_PATH}")
    message(STATUS "FMOD: Using plugin's jniLibs at ${FMOD_LIB_DIR}")
else()
    # Default to app path - will fail at link time with helpful error
    set(FMOD_LIB_DIR "${APP_JNILIBS_PATH}")
    message(WARNING "FMOD: No native libraries found! Run 'dart run fmod_flutter:setup_fmod' from your project root.")
endif()

# Add JNI source file
add_library(
    fmod_flutter
    SHARED
    fmod_jni.cpp
)

# Find Android log library
find_library(
    log-lib
    log
)

# FMOD core library (prebuilt)
add_library(
    fmod
    SHARED
    IMPORTED
)
set_target_properties(
    fmod
    PROPERTIES IMPORTED_LOCATION
    "${FMOD_LIB_DIR}/libfmod.so"
)

# FMOD studio library (prebuilt)
add_library(
    fmodstudio
    SHARED
    IMPORTED
)
set_target_properties(
    fmodstudio
    PROPERTIES IMPORTED_LOCATION
    "${FMOD_LIB_DIR}/libfmodstudio.so"
)

# Include directories for FMOD headers
# These are copied by the setup script
target_include_directories(
    fmod_flutter
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/include
)

# Link libraries
target_link_libraries(
    fmod_flutter
    ${log-lib}
    fmod
    fmodstudio
)

