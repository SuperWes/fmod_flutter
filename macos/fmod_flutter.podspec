#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fmod_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fmod_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for FMOD Studio audio engine.'
  s.description      = <<-DESC
A Flutter plugin for integrating FMOD Studio audio engine for advanced game audio.
                       DESC
  s.homepage         = 'https://github.com/SuperWes/fmod_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Midnight Launch Games' => 'support@midnightlaunchgames.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.swift_version = '5.0'

  s.libraries = 'c++'

  # Preserve FMOD directory structure if present (for local development)
  s.preserve_paths = 'FMOD/**/*'

  # FMOD libraries are expected in the plugin's macos/FMOD/ directory
  # Run `dart run fmod_flutter:setup_fmod` to set this up
  #
  # Directory structure:
  #   macos/FMOD/include/   - Header files
  #   macos/FMOD/lib/       - Dynamic libraries (libfmod.dylib, libfmodstudio.dylib)

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    # Header search path for FMOD includes
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/../FMOD/include',
    # Link FMOD dynamic libraries
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -L$(PODS_ROOT)/../FMOD/lib -lfmod -lfmodstudio',
    # Runtime library search path
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @loader_path/../Frameworks @executable_path/../Frameworks'
  }

  # Copy FMOD dylibs so they can be found at runtime.
  # The setup script places them in <project>/macos/FMOD/lib/ (consumer) or
  # <plugin>/macos/FMOD/lib/ (plugin development). CocoaPods doesn't embed
  # bare dylibs automatically — this script phase copies them into the built
  # fmod_flutter.framework at Versions/Frameworks/, which matches the existing
  # @loader_path/../Frameworks rpath entry. When CocoaPods' "Embed Pods
  # Frameworks" phase copies fmod_flutter.framework into the app bundle,
  # these dylibs come along and dyld can find them.
  s.script_phase = {
    :name => 'Copy FMOD Libraries',
    :script => %q{
      FMOD_LIB_DIR="${PODS_ROOT}/../FMOD/lib"
      if [ ! -d "${FMOD_LIB_DIR}" ]; then
        FMOD_LIB_DIR="${PODS_TARGET_SRCROOT}/FMOD/lib"
      fi
      FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/fmod_flutter.framework/Versions/Frameworks"
      if [ -d "${FMOD_LIB_DIR}" ]; then
        mkdir -p "${FRAMEWORKS_DIR}"
        cp -f "${FMOD_LIB_DIR}/libfmod.dylib" "${FRAMEWORKS_DIR}/"
        cp -f "${FMOD_LIB_DIR}/libfmodstudio.dylib" "${FRAMEWORKS_DIR}/"
        install_name_tool -id "@rpath/libfmod.dylib" "${FRAMEWORKS_DIR}/libfmod.dylib" 2>/dev/null || true
        install_name_tool -id "@rpath/libfmodstudio.dylib" "${FRAMEWORKS_DIR}/libfmodstudio.dylib" 2>/dev/null || true
        echo "Copied FMOD libraries to ${FRAMEWORKS_DIR}"
      else
        echo "warning: FMOD libraries not found. Run dart run fmod_flutter:setup_fmod first."
      fi
    },
    :execution_position => :after_compile
  }
end
