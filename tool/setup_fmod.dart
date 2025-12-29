#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🎵 FMOD Flutter Setup Script\n');

  // Get the package root (where this script should be run from)
  final packageRoot = Directory.current;
  final enginesDir = Directory('${packageRoot.path}/engines');

  if (!await enginesDir.exists()) {
    print('❌ engines/ directory not found!');
    print('   Expected: ${enginesDir.path}');
    print('\n📋 Setup Instructions:');
    print('   1. Create the directory: mkdir engines');
    print('   2. Download FMOD Studio API from https://www.fmod.com/download');
    print('   3. Place the downloaded files in engines/:');
    print('      - fmodstudioapi*android.tar.gz');
    print('      - fmodstudioapi*ios-installer.dmg');
    print('      - fmodstudioapi*html5.zip');
    print('   4. Run this script again\n');
    exit(1);
  }

  print('📁 Package root: ${packageRoot.path}');
  print('📁 Engines dir: ${enginesDir.path}\n');

  // Extract any compressed archives first
  await extractArchives(enginesDir);

  var success = true;

  // Setup Android
  success = await setupAndroid(packageRoot, enginesDir) && success;
  
  // Setup iOS
  success = await setupIOS(packageRoot, enginesDir) && success;
  
  // Setup Web
  success = await setupWeb(packageRoot, enginesDir) && success;

  if (success) {
    print('\n✅ FMOD setup complete!');
    print('   You can now build the example app.');
  } else {
    print('\n⚠️  Setup completed with warnings.');
    print('   Check the messages above for details.');
  }
}

Future<void> extractArchives(Directory enginesDir) async {
  print('📦 Checking for compressed archives...\n');

  final entities = await enginesDir.list().toList();
  var extracted = false;

  for (final entity in entities) {
    if (entity is! File) continue;
    
    final path = entity.path;
    final fileName = path.split('/').last;

    // Android: .tar.gz
    if (fileName.endsWith('.tar.gz') && fileName.contains('android')) {
      print('   Found Android archive: $fileName');
      final destDir = Directory('${enginesDir.path}/android');
      await destDir.create(recursive: true);
      
      final result = await Process.run(
        'tar',
        ['-xzf', path, '-C', destDir.path],
      );
      
      if (result.exitCode == 0) {
        print('   ✓ Extracted to android/');
        extracted = true;
      } else {
        print('   ⚠️  Failed to extract: ${result.stderr}');
      }
    }
    
    // iOS: .dmg or .tar.gz
    else if ((fileName.endsWith('.dmg') || fileName.endsWith('.tar.gz')) && 
             (fileName.contains('ios') || fileName.contains('fmodstudioapi'))) {
      print('   Found iOS archive: $fileName');
      final destDir = Directory('${enginesDir.path}/ios');
      await destDir.create(recursive: true);
      
      if (fileName.endsWith('.dmg')) {
        // Mount DMG, copy contents, unmount
        print('   Mounting DMG...');
        
        // Mount the DMG
        var result = await Process.run('hdiutil', ['attach', path, '-nobrowse', '-quiet']);
        
        if (result.exitCode == 0) {
          // Give it a moment to mount
          await Future.delayed(Duration(seconds: 1));
          
          // Find the mounted volume
          final volumes = await Directory('/Volumes').list().toList();
          Directory? fmodVolume;
          
          for (final vol in volumes) {
            if (vol is Directory) {
              final volName = vol.path.split('/').last.toLowerCase();
              if (volName.contains('fmod') && !volName.contains('studio')) {
                fmodVolume = vol;
                break;
              }
            }
          }
          
          if (fmodVolume != null) {
            print('   Mounted at: ${fmodVolume.path}');
            
            // Look for the FMOD SDK directory inside
            final contents = await fmodVolume.list().toList();
            Directory? sdkDir;
            
            // First try to find fmodstudioapi directory
            for (final item in contents) {
              if (item is Directory && item.path.contains('fmodstudioapi')) {
                sdkDir = item;
                break;
              }
            }
            
            // If not found, look for "FMOD Programmers API" directory
            if (sdkDir == null) {
              for (final item in contents) {
                if (item is Directory && item.path.contains('FMOD Programmers API')) {
                  sdkDir = item;
                  break;
                }
              }
            }
            
            if (sdkDir != null) {
              // Copy SDK to engines/ios/ with a consistent name
              // Extract version from filename if possible
              var sdkName = sdkDir.path.split('/').last;
              if (sdkName.contains('FMOD Programmers API')) {
                // Use filename to get version
                final match = RegExp(r'fmodstudioapi(\d+)').firstMatch(fileName);
                if (match != null) {
                  sdkName = 'fmodstudioapi${match.group(1)}ios';
                } else {
                  sdkName = 'fmodstudioapi-ios';
                }
              }
              
              final targetDir = Directory('${destDir.path}/$sdkName');
              print('   Copying to $sdkName...');
              await _copyDirectory(sdkDir, targetDir);
              print('   ✓ Extracted to ios/$sdkName');
              extracted = true;
            } else {
              print('   ⚠️  Could not find FMOD SDK in mounted volume');
              print('      Available items:');
              for (final item in contents) {
                print('      - ${item.path.split('/').last}');
              }
            }
            
            // Unmount
            print('   Unmounting...');
            await Process.run('hdiutil', ['detach', fmodVolume.path, '-quiet']);
          } else {
            print('   ⚠️  Could not find mounted FMOD volume');
            // Try to unmount any FMOD volumes
            await Process.run('hdiutil', ['detach', '/Volumes/FMOD*', '-quiet']);
          }
        } else {
          print('   ⚠️  Failed to mount DMG: ${result.stderr}');
        }
      } else {
        // .tar.gz for iOS
        final result = await Process.run(
          'tar',
          ['-xzf', path, '-C', destDir.path],
        );
        
        if (result.exitCode == 0) {
          print('   ✓ Extracted to ios/');
          extracted = true;
        } else {
          print('   ⚠️  Failed to extract: ${result.stderr}');
        }
      }
    }
    
    // HTML5: .zip
    else if (fileName.endsWith('.zip') && 
             (fileName.contains('html5') || fileName.contains('emscripten'))) {
      print('   Found HTML5 archive: $fileName');
      final destDir = Directory('${enginesDir.path}/html5');
      await destDir.create(recursive: true);
      
      final result = await Process.run(
        'unzip',
        ['-q', '-o', path, '-d', destDir.path],
      );
      
      if (result.exitCode == 0) {
        print('   ✓ Extracted to html5/');
        extracted = true;
      } else {
        print('   ⚠️  Failed to extract: ${result.stderr}');
      }
    }
  }

  if (extracted) {
    print('\n');
  } else {
    print('   No archives found (already extracted?)\n');
  }
}

Future<bool> setupAndroid(Directory packageRoot, Directory enginesDir) async {
  print('🤖 Setting up Android...');

  final androidEngineDir = Directory('${enginesDir.path}/android');
  if (!await androidEngineDir.exists()) {
    print('   ⚠️  android/ not found in engines/');
    return false;
  }

  // Find FMOD SDK directory
  final sdkDirs = await androidEngineDir
      .list()
      .where((entity) =>
          entity is Directory && entity.path.contains('fmodstudio'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   ❌ No FMOD SDK found in engines/android/');
    print('      Expected: engines/android/fmodstudio20XXX/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found SDK: ${sdkDir.path.split('/').last}');

  // Copy .jar files to plugin's libs directory
  final libsDestDir = Directory('${packageRoot.path}/android/libs');
  await libsDestDir.create(recursive: true);

  var copied = 0;
  
  // Copy fmod.jar from core
  final coreJar = File('${sdkDir.path}/api/core/lib/fmod.jar');
  if (await coreJar.exists()) {
    await coreJar.copy('${libsDestDir.path}/fmod.jar');
    copied++;
    print('   ✓ Copied fmod.jar to plugin');
  }

  if (copied == 0) {
    print('   ⚠️  No .jar files found');
    return false;
  }
  
  // Copy header files to plugin's libs/include directory
  print('   Copying header files...');
  final includeDir = Directory('${libsDestDir.path}/include');
  await includeDir.create(recursive: true);
  
  var headersCopied = 0;
  
  // Copy core headers
  final coreIncDir = Directory('${sdkDir.path}/api/core/inc');
  if (await coreIncDir.exists()) {
    await for (final entity in coreIncDir.list()) {
      if (entity is File && (entity.path.endsWith('.h') || entity.path.endsWith('.hpp'))) {
        final fileName = entity.path.split('/').last;
        await entity.copy('${includeDir.path}/$fileName');
        headersCopied++;
      }
    }
  }
  
  // Copy studio headers
  final studioIncDir = Directory('${sdkDir.path}/api/studio/inc');
  if (await studioIncDir.exists()) {
    await for (final entity in studioIncDir.list()) {
      if (entity is File && (entity.path.endsWith('.h') || entity.path.endsWith('.hpp'))) {
        final fileName = entity.path.split('/').last;
        await entity.copy('${includeDir.path}/$fileName');
        headersCopied++;
      }
    }
  }
  
  print('   ✓ Copied $headersCopied header files to android/libs/include/');

  // Copy native .so libraries to plugin's jniLibs directory (for CMake)
  print('   Copying native libraries to plugin...');
  final pluginJniLibsDir = Directory('${packageRoot.path}/android/src/main/jniLibs');
  
  final architectures = ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'];
  var pluginSoFiles = 0;
  
  for (final arch in architectures) {
    final archDestDir = Directory('${pluginJniLibsDir.path}/$arch');
    await archDestDir.create(recursive: true);
    
    // Copy core library
    final coreLib = File('${sdkDir.path}/api/core/lib/$arch/libfmod.so');
    if (await coreLib.exists()) {
      await coreLib.copy('${archDestDir.path}/libfmod.so');
      pluginSoFiles++;
    }
    
    // Copy studio library
    final studioLib = File('${sdkDir.path}/api/studio/lib/$arch/libfmodstudio.so');
    if (await studioLib.exists()) {
      await studioLib.copy('${archDestDir.path}/libfmodstudio.so');
      pluginSoFiles++;
    }
  }
  
  if (pluginSoFiles > 0) {
    print('   ✓ Copied $pluginSoFiles native library file(s) to plugin');
  } else {
    print('   ⚠️  No native libraries found');
    return false;
  }
  
  // Also copy to example app if it exists
  final exampleJniLibsDir = Directory('${packageRoot.path}/example/android/app/src/main/jniLibs');
  if (await Directory('${packageRoot.path}/example').exists()) {
    print('   Copying native libraries to example app...');
    var exampleSoFiles = 0;
    
    for (final arch in architectures) {
      final archDestDir = Directory('${exampleJniLibsDir.path}/$arch');
      await archDestDir.create(recursive: true);
      
      // Copy core library
      final coreLib = File('${sdkDir.path}/api/core/lib/$arch/libfmod.so');
      if (await coreLib.exists()) {
        await coreLib.copy('${archDestDir.path}/libfmod.so');
        exampleSoFiles++;
      }
      
      // Copy studio library
      final studioLib = File('${sdkDir.path}/api/studio/lib/$arch/libfmodstudio.so');
      if (await studioLib.exists()) {
        await studioLib.copy('${archDestDir.path}/libfmodstudio.so');
        exampleSoFiles++;
      }
    }
    
    if (exampleSoFiles > 0) {
      print('   ✓ Copied $exampleSoFiles native library file(s) to example app');
    }
  }
  
  // If running from user's project, also copy to their app
  final userAppJniLibsDir = Directory('${packageRoot.path}/android/app/src/main/jniLibs');
  if (await Directory('${packageRoot.path}/android/app').exists() && 
      !await Directory('${packageRoot.path}/example').exists()) {
    print('   Copying native libraries to your app...');
    var userSoFiles = 0;
    
    for (final arch in architectures) {
      final archDestDir = Directory('${userAppJniLibsDir.path}/$arch');
      await archDestDir.create(recursive: true);
      
      // Copy core library
      final coreLib = File('${sdkDir.path}/api/core/lib/$arch/libfmod.so');
      if (await coreLib.exists()) {
        await coreLib.copy('${archDestDir.path}/libfmod.so');
        userSoFiles++;
      }
      
      // Copy studio library
      final studioLib = File('${sdkDir.path}/api/studio/lib/$arch/libfmodstudio.so');
      if (await studioLib.exists()) {
        await studioLib.copy('${archDestDir.path}/libfmodstudio.so');
        userSoFiles++;
      }
    }
    
    if (userSoFiles > 0) {
      print('   ✓ Copied $userSoFiles native library file(s) to your app');
    }
  }

  print('   ✓ Android FMOD libraries ready');
  return true;
}

Future<bool> setupIOS(Directory packageRoot, Directory enginesDir) async {
  print('\n🍎 Setting up iOS...');

  final iosEngineDir = Directory('${enginesDir.path}/ios');
  if (!await iosEngineDir.exists()) {
    print('   ⚠️  ios/ not found in engines/');
    return false;
  }

  // Find FMOD SDK directory
  final sdkDirs = await iosEngineDir
      .list()
      .where((entity) =>
          entity is Directory && entity.path.contains('fmodstudioapi'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   ❌ No FMOD SDK found in engines/ios/');
    print('      Expected: engines/ios/fmodstudioapi20XXX/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found SDK: ${sdkDir.path.split('/').last}');

  // Create FMOD directory structure
  final fmodDeviceLibDir = Directory('${packageRoot.path}/ios/FMOD/lib/device');
  final fmodSimLibDir = Directory('${packageRoot.path}/ios/FMOD/lib/simulator');
  final fmodIncludeDir = Directory('${packageRoot.path}/ios/FMOD/include');
  await fmodDeviceLibDir.create(recursive: true);
  await fmodSimLibDir.create(recursive: true);
  await fmodIncludeDir.create(recursive: true);

  var copied = 0;

  // Copy static libraries (.a files) - organized by device/simulator
  final libFiles = [
    {'file': 'libfmod_iphoneos.a', 'studio': false, 'sim': false},
    {'file': 'libfmod_iphonesimulator.a', 'studio': false, 'sim': true},
    {'file': 'libfmodstudio_iphoneos.a', 'studio': true, 'sim': false},
    {'file': 'libfmodstudio_iphonesimulator.a', 'studio': true, 'sim': true},
  ];

  for (final libInfo in libFiles) {
    final isStudio = libInfo['studio'] as bool;
    final isSimulator = libInfo['sim'] as bool;
    final fileName = libInfo['file'] as String;
    
    final srcPath = isStudio
        ? '${sdkDir.path}/api/studio/lib/$fileName'
        : '${sdkDir.path}/api/core/lib/$fileName';
    
    final srcFile = File(srcPath);
    if (await srcFile.exists()) {
      final destDir = isSimulator ? fmodSimLibDir : fmodDeviceLibDir;
      await srcFile.copy('${destDir.path}/$fileName');
      copied++;
    }
  }

  print('   ✓ Copied $copied static libraries (organized by device/simulator)');

  // Copy header files
  final coreIncDir = Directory('${sdkDir.path}/api/core/inc');
  final studioIncDir = Directory('${sdkDir.path}/api/studio/inc');

  var headersCopied = 0;
  if (await coreIncDir.exists()) {
    await for (final entity in coreIncDir.list()) {
      if (entity is File && entity.path.endsWith('.h')) {
        final fileName = entity.path.split('/').last;
        await entity.copy('${fmodIncludeDir.path}/$fileName');
        headersCopied++;
      }
    }
  }

  if (await studioIncDir.exists()) {
    await for (final entity in studioIncDir.list()) {
      if (entity is File && entity.path.endsWith('.h')) {
        final fileName = entity.path.split('/').last;
        await entity.copy('${fmodIncludeDir.path}/$fileName');
        headersCopied++;
      }
    }
  }

  print('   ✓ Copied $headersCopied header files');

  if (copied > 0 && headersCopied > 0) {
    print('   ✓ iOS FMOD libraries ready at ios/FMOD/');
    return true;
  } else {
    print('   ⚠️  No libraries or headers found');
    return false;
  }
}

Future<bool> setupWeb(Directory packageRoot, Directory enginesDir) async {
  print('\n🌐 Setting up Web (HTML5)...');

  final html5EngineDir = Directory('${enginesDir.path}/html5');
  if (!await html5EngineDir.exists()) {
    print('   ⚠️  html5/ not found in engines/');
    return false;
  }

  // Find FMOD SDK directory
  final sdkDirs = await html5EngineDir
      .list()
      .where((entity) =>
          entity is Directory && entity.path.contains('fmodstudio'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   ❌ No FMOD SDK found in engines/html5/');
    print('      Expected: engines/html5/fmodstudio20XXX/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found SDK: ${sdkDir.path.split('/').last}');

  // Copy WASM and JS files from wasm/ subdirectory
  final webDestDir = Directory('${packageRoot.path}/web/assets/fmod');
  await webDestDir.create(recursive: true);

  final filesToCopy = [
    {'src': '${sdkDir.path}/api/core/lib/wasm/fmod.js', 'name': 'fmod.js'},
    {'src': '${sdkDir.path}/api/core/lib/wasm/fmod.wasm', 'name': 'fmod.wasm'},
    {'src': '${sdkDir.path}/api/studio/lib/wasm/fmodstudio.js', 'name': 'fmodstudio.js'},
    {'src': '${sdkDir.path}/api/studio/lib/wasm/fmodstudio.wasm', 'name': 'fmodstudio.wasm'},
  ];

  var copied = 0;
  for (final fileInfo in filesToCopy) {
    final file = File(fileInfo['src']!);
    if (await file.exists()) {
      await file.copy('${webDestDir.path}/${fileInfo['name']}');
      copied++;
      print('   ✓ Copied ${fileInfo['name']}');
    }
  }

  if (copied > 0) {
    print('   ✓ Copied $copied file(s) to web/assets/fmod/');
  } else {
    print('   ⚠️  No WASM/JS files found');
    return false;
  }

  // Also copy to example app's web directory
  print('   Copying FMOD files to example/web/fmod/...');
  final exampleWebDir = Directory('${packageRoot.path}/example/web/fmod');
  await exampleWebDir.create(recursive: true);
  
  var exampleCopied = 0;
  for (final fileInfo in filesToCopy) {
    final file = File(fileInfo['src']!);
    if (await file.exists()) {
      await file.copy('${exampleWebDir.path}/${fileInfo['name']}');
      exampleCopied++;
    }
  }
  
  if (exampleCopied > 0) {
    print('   ✓ Copied $exampleCopied file(s) to example/web/fmod/');
  }

  return true;
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    if (entity is Directory) {
      final newDirectory =
          Directory('${destination.path}/${entity.path.split('/').last}');
      await _copyDirectory(entity, newDirectory);
    } else if (entity is File) {
      await entity.copy('${destination.path}/${entity.path.split('/').last}');
    }
  }
}
