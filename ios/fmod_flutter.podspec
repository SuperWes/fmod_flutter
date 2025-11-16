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
  s.homepage         = 'https://github.com/yourusername/fmod_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.swift_version = '5.0'
  
  # FMOD libraries linking is handled in the app's Podfile post_install hook
  # This allows users to place FMOD SDK in their app directory or use setup script
  # 
  # See README.md for setup instructions
  # 
  # Example Podfile configuration:
  # if target.name == 'fmod_flutter'
  #   config.build_settings['HEADER_SEARCH_PATHS'] = ['$(inherited)', '$(PROJECT_DIR)/../FMOD/include']
  #   # Add appropriate library linking based on your FMOD location
  # end
  
  s.frameworks = 'AudioToolbox', 'AVFoundation'
  s.libraries = 'c++'
  
  # Preserve FMOD directory structure if present (for local development)
  s.preserve_paths = 'FMOD/**/*'
end
