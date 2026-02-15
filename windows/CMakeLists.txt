cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "fmod_flutter_plugin")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "fmod_flutter_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "fmod_flutter_plugin.cpp"
  "fmod_flutter_plugin.h"
  "fmod_bridge.cpp"
  "fmod_bridge.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/fmod_flutter/fmod_flutter_plugin_c_api.h"
  "fmod_flutter_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# FMOD setup
# FMOD libraries are expected in windows/FMOD/ directory
# Run `dart run fmod_flutter:setup_fmod` to set this up
#
# Directory structure:
#   windows/FMOD/include/   - Header files
#   windows/FMOD/lib/       - Import libraries (fmod_vc.lib, fmodstudio_vc.lib)
#   windows/FMOD/dll/       - DLLs (fmod.dll, fmodstudio.dll)

set(FMOD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/FMOD")

# FMOD include directory
target_include_directories(${PLUGIN_NAME} PRIVATE "${FMOD_DIR}/include")

# Link FMOD import libraries
target_link_libraries(${PLUGIN_NAME} PRIVATE
  "${FMOD_DIR}/lib/fmod_vc.lib"
  "${FMOD_DIR}/lib/fmodstudio_vc.lib"
)

# Copy FMOD DLLs to the output directory so they're bundled with the app
set(FMOD_DLLS
  "${FMOD_DIR}/dll/fmod.dll"
  "${FMOD_DIR}/dll/fmodstudio.dll"
)

# Install DLLs alongside the executable
foreach(FMOD_DLL ${FMOD_DLLS})
  if(EXISTS "${FMOD_DLL}")
    install(FILES "${FMOD_DLL}" DESTINATION "${CMAKE_INSTALL_PREFIX}" COMPONENT Runtime)
  endif()
endforeach()

# List of absolute paths to libraries that should be bundled with the plugin.
# This is used by the Flutter tool to copy the libraries to the output directory.
set(fmod_flutter_plugin_bundled_libraries
  "${FMOD_DIR}/dll/fmod.dll"
  "${FMOD_DIR}/dll/fmodstudio.dll"
  PARENT_SCOPE
)
