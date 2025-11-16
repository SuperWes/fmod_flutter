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
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # Add FMOD framework dependency
  # User must place fmod framework in ios/Frameworks/
  s.vendored_frameworks = 'Frameworks/fmod.framework'
  s.frameworks = 'AudioToolbox', 'AVFoundation'
end

