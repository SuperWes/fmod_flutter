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
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
  
  s.frameworks = 'AudioToolbox', 'AVFoundation'
  s.libraries = 'c++'
  
  # Preserve FMOD directory structure if present (for local development)
  s.preserve_paths = 'FMOD/**/*'
  
  # FMOD libraries are expected in the app's ios/FMOD/ directory
  # Run `dart run fmod_flutter:setup_fmod` to set this up
  # 
  # Directory structure:
  #   ios/FMOD/include/         - Header files
  #   ios/FMOD/lib/device/      - Device libraries (libfmod_iphoneos.a, libfmodstudio_iphoneos.a)
  #   ios/FMOD/lib/simulator/   - Simulator libraries (libfmod_iphonesimulator.a, libfmodstudio_iphonesimulator.a)
  
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    # Header search path for FMOD includes (in app's ios/FMOD/include/)
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/../FMOD/include',
    # Link device libraries when building for real iOS devices
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -ObjC -force_load $(PODS_ROOT)/../FMOD/lib/device/libfmod_iphoneos.a -force_load $(PODS_ROOT)/../FMOD/lib/device/libfmodstudio_iphoneos.a',
    # Link simulator libraries when building for iOS Simulator
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -ObjC -force_load $(PODS_ROOT)/../FMOD/lib/simulator/libfmod_iphonesimulator.a -force_load $(PODS_ROOT)/../FMOD/lib/simulator/libfmodstudio_iphonesimulator.a'
  }
end
