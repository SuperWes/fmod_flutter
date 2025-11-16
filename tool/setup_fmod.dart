#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🎵 FMOD Flutter Setup Script\n');

  final scriptDir = Directory.current;
  final packageRoot = scriptDir.parent;
  final enginesDir = Directory('${packageRoot.path}/engines');

  if (!await enginesDir.exists()) {
    print('❌ engines/ directory not found!');
    print('   Please create it and add FMOD Engine SDKs.');
    print('   See engines/README.md for instructions.\n');
    exit(1);
  }

  print('📁 Package root: ${packageRoot.path}');
  print('📁 Engines dir: ${enginesDir.path}\n');

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

  // Copy .aar files
  final libsDestDir = Directory('${packageRoot.path}/android/libs');
  await libsDestDir.create(recursive: true);

  final aarFiles = [
    '${sdkDir.path}/api/core/lib/fmod.aar',
    '${sdkDir.path}/api/studio/lib/fmod.aar',
  ];

  var copied = 0;
  for (final aarPath in aarFiles) {
    final aarFile = File(aarPath);
    if (await aarFile.exists()) {
      final fileName = aarPath.contains('core') ? 'fmod-core.aar' : 'fmod-studio.aar';
      await aarFile.copy('${libsDestDir.path}/$fileName');
      copied++;
    }
  }

  if (copied > 0) {
    print('   ✓ Copied $copied .aar file(s) to android/libs/');
  } else {
    print('   ⚠️  No .aar files found');
    return false;
  }

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

  // Copy frameworks
  final frameworksDestDir = Directory('${packageRoot.path}/ios/Frameworks');
  await frameworksDestDir.create(recursive: true);

  final frameworks = [
    'fmod.xcframework',
    'fmod_studio.xcframework',
  ];

  var copied = 0;
  for (final framework in frameworks) {
    final srcPath = '${sdkDir.path}/api/core/lib/$framework';
    final studioSrcPath = '${sdkDir.path}/api/studio/lib/$framework';
    
    final srcDir = await Directory(srcPath).exists()
        ? Directory(srcPath)
        : (await Directory(studioSrcPath).exists()
            ? Directory(studioSrcPath)
            : null);

    if (srcDir != null) {
      final destPath = '${frameworksDestDir.path}/$framework';
      
      // Remove existing if present
      final destDir = Directory(destPath);
      if (await destDir.exists()) {
        await destDir.delete(recursive: true);
      }

      // Copy recursively
      await _copyDirectory(srcDir, destDir);
      copied++;
    }
  }

  if (copied > 0) {
    print('   ✓ Copied $copied framework(s) to ios/Frameworks/');
  } else {
    print('   ⚠️  No frameworks found');
    return false;
  }

  return true;
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

  // Copy WASM and JS files
  final webDestDir = Directory('${packageRoot.path}/web/assets/fmod');
  await webDestDir.create(recursive: true);

  final files = [
    '${sdkDir.path}/api/core/lib/fmodstudio.js',
    '${sdkDir.path}/api/core/lib/fmodstudio.wasm',
  ];

  var copied = 0;
  for (final filePath in files) {
    final file = File(filePath);
    if (await file.exists()) {
      final fileName = filePath.split('/').last;
      await file.copy('${webDestDir.path}/$fileName');
      copied++;
    }
  }

  if (copied > 0) {
    print('   ✓ Copied $copied file(s) to web/assets/fmod/');
  } else {
    print('   ⚠️  No WASM/JS files found');
    return false;
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

