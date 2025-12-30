cmake_minimum_required(VERSION 3.10)

project(fmod_flutter)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find FMOD libraries path
# Gradle's copyFmodLibs task copies libs from app's jniLibs to plugin's jniLibs before build
set(FMOD_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}")

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

