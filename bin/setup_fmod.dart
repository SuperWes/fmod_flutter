/// FMOD Flutter Setup Script
/// This script should be run from your Flutter project root.
///
/// Usage:
///   dart run fmod_flutter:setup_fmod
///
/// This will:
/// 1. Look for FMOD SDK archives in engines/
/// 2. Extract them if needed
/// 3. Copy native libraries to your project's android/, ios/, and web/ directories

import 'dart:io';

void main() async {
  print('ðŸŽµ FMOD Flutter Setup\n');

  // This script runs from the user's project root
  final projectRoot = Directory.current;
  final enginesDir = Directory('${projectRoot.path}/engines');

  print('ðŸ“ Project root: ${projectRoot.path}');
  print('ðŸ“ Looking for FMOD SDKs in: ${enginesDir.path}\n');

  // Check if project has pubspec.yaml (sanity check)
  final pubspecFile = File('${projectRoot.path}/pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('âŒ No pubspec.yaml found in current directory!');
    print('   Please run this command from your Flutter project root.\n');
    exit(1);
  }

  // Check if engines directory exists
  if (!await enginesDir.exists()) {
    print('âŒ engines/ directory not found!');
    print('\nðŸ“– Setup Instructions:\n');
    print('1. Create a directory named "engines" in your project root:');
    print('   mkdir engines\n');
    print('2. Download FMOD Engine SDKs from https://www.fmod.com/download');
    print('   (Requires free account)\n');
    print('3. Place the downloaded files in engines/:');
    print('   - fmodstudioapi*android.tar.gz');
    print('   - fmodstudioapi*ios-installer.dmg');
    print('   - fmodstudioapi*mac-installer.dmg');
    print('   - fmodstudioapi*html5.zip');
    print('   - Windows: run fmodstudioapi*win-installer.exe, then copy the');
    print('     installed folder to engines/windows/fmodstudioapi*win/\n');
    print('4. Run this command again: dart run fmod_flutter:setup_fmod\n');
    exit(1);
  }

  // Extract archives if needed
  await extractArchives(enginesDir);

  var success = true;

  // Setup Android
  success = await setupAndroid(projectRoot, enginesDir) && success;

  // Setup iOS
  success = await setupIOS(projectRoot, enginesDir) && success;

  // Setup macOS
  success = await setupMacOS(projectRoot, enginesDir) && success;

  // Setup Windows
  success = await setupWindows(projectRoot, enginesDir) && success;

  // Setup Web
  success = await setupWeb(projectRoot, enginesDir) && success;

  if (success) {
    print('\nâœ… FMOD setup complete!');
    print('   Your project is now configured to use FMOD on all platforms.');
    print('\nðŸ“ Next steps:');
    print('   1. Place your FMOD bank files in assets/audio/');
    print('   2. Update pubspec.yaml to include your banks as assets');
    print('   3. Run: flutter run');
    print('\nðŸ“š See the plugin documentation for usage examples.\n');
  } else {
    print('\nâš ï¸  Setup completed with warnings.');
    print('   Check the messages above for details.\n');
  }
}

Future<void> extractArchives(Directory enginesDir) async {
  print('ðŸ“¦ Checking for FMOD SDK archives...\n');

  final entities = await enginesDir.list().toList();
  var extracted = false;

  for (final entity in entities) {
    if (entity is! File) continue;

    final path = entity.path;
    final fileName = path.split(RegExp(r'[/\\]')).last;

    // Android: .tar.gz
    if (fileName.endsWith('.tar.gz') && fileName.contains('android')) {
      print('   Found Android SDK: $fileName');
      final destDir = Directory('${enginesDir.path}/android');
      await destDir.create(recursive: true);

      final result = await Process.run(
        'tar',
        ['-xzf', path, '-C', destDir.path],
      );

      if (result.exitCode == 0) {
        print('   âœ“ Extracted to engines/android/');
        extracted = true;
      } else {
        print('   âš ï¸  Failed to extract: ${result.stderr}');
      }
    }

    // iOS: .dmg
    else if (fileName.endsWith('.dmg') && fileName.contains('ios')) {
      print('   Found iOS SDK: $fileName');
      final destDir = Directory('${enginesDir.path}/ios');
      await destDir.create(recursive: true);

      print('   Mounting DMG...');
      var result =
          await Process.run('hdiutil', ['attach', path, '-nobrowse', '-quiet']);

      if (result.exitCode == 0) {
        await Future.delayed(const Duration(seconds: 1));

        // Find mounted volume
        final volumes = await Directory('/Volumes').list().toList();
        Directory? fmodVolume;

        for (final vol in volumes) {
          if (vol is Directory) {
            final volName = vol.path.split(RegExp(r'[/\\]')).last.toLowerCase();
            if (volName.contains('fmod') && !volName.contains('studio')) {
              fmodVolume = vol;
              break;
            }
          }
        }

        if (fmodVolume != null) {
          // Find SDK directory
          final contents = await fmodVolume.list().toList();
          Directory? sdkDir;

          for (final item in contents) {
            if (item is Directory &&
                (item.path.contains('fmodstudioapi') ||
                    item.path.contains('FMOD Programmers API'))) {
              sdkDir = item;
              break;
            }
          }

          if (sdkDir != null) {
            var sdkName = sdkDir.path.split(RegExp(r'[/\\]')).last;
            if (sdkName.contains('FMOD Programmers API')) {
              final match = RegExp(r'fmodstudioapi(\d+)').firstMatch(fileName);
              sdkName = match != null
                  ? 'fmodstudioapi${match.group(1)}ios'
                  : 'fmodstudioapi-ios';
            }

            final targetDir = Directory('${destDir.path}/$sdkName');
            print('   Copying SDK...');
            await _copyDirectory(sdkDir, targetDir);
            print('   âœ“ Extracted to engines/ios/$sdkName');
            extracted = true;
          }

          await Process.run('hdiutil', ['detach', fmodVolume.path, '-quiet']);
        }
      }
    }

    // macOS: .dmg
    else if (fileName.endsWith('.dmg') && fileName.contains('mac')) {
      print('   Found macOS SDK: $fileName');
      final destDir = Directory('${enginesDir.path}/macos');
      await destDir.create(recursive: true);

      print('   Mounting DMG...');
      var result =
          await Process.run('hdiutil', ['attach', path, '-nobrowse', '-quiet']);

      if (result.exitCode == 0) {
        await Future.delayed(const Duration(seconds: 1));

        final volumes = await Directory('/Volumes').list().toList();
        Directory? fmodVolume;

        for (final vol in volumes) {
          if (vol is Directory) {
            final volName = vol.path.split(RegExp(r'[/\\]')).last.toLowerCase();
            if (volName.contains('fmod') && !volName.contains('studio')) {
              fmodVolume = vol;
              break;
            }
          }
        }

        if (fmodVolume != null) {
          final contents = await fmodVolume.list().toList();
          Directory? sdkDir;

          for (final item in contents) {
            if (item is Directory &&
                (item.path.contains('fmodstudioapi') ||
                    item.path.contains('FMOD Programmers API'))) {
              sdkDir = item;
              break;
            }
          }

          if (sdkDir != null) {
            var sdkName = sdkDir.path.split(RegExp(r'[/\\]')).last;
            if (sdkName.contains('FMOD Programmers API')) {
              final match = RegExp(r'fmodstudioapi(\d+)').firstMatch(fileName);
              sdkName = match != null
                  ? 'fmodstudioapi${match.group(1)}mac'
                  : 'fmodstudioapi-mac';
            }

            final targetDir = Directory('${destDir.path}/$sdkName');
            print('   Copying SDK...');
            await _copyDirectory(sdkDir, targetDir);
            print('   \u2713 Extracted to engines/macos/$sdkName');
            extracted = true;
          }

          await Process.run('hdiutil', ['detach', fmodVolume.path, '-quiet']);
        }
      }
    }

    // Web/HTML5: .zip
    else if (fileName.endsWith('.zip') && fileName.contains('html5')) {
      print('   Found HTML5 SDK: $fileName');
      final destDir = Directory('${enginesDir.path}/html5');
      await destDir.create(recursive: true);

      final result = await Process.run(
        'unzip',
        ['-q', '-o', path, '-d', destDir.path],
      );

      if (result.exitCode == 0) {
        print('   âœ“ Extracted to engines/html5/');
        extracted = true;
      } else {
        print('   âš ï¸  Failed to extract: ${result.stderr}');
      }
    }
  }

  if (extracted) {
    print('');
  } else {
    print('   SDKs already extracted.\n');
  }
}

Future<bool> setupAndroid(Directory projectRoot, Directory enginesDir) async {
  print('ðŸ¤– Setting up Android...');

  final androidSdkDir = Directory('${enginesDir.path}/android');
  if (!await androidSdkDir.exists()) {
    print('   âš ï¸  android/ not found in engines/');
    print('   Skipping Android setup.');
    return false;
  }

  // Find FMOD SDK
  final sdkDirs = await androidSdkDir
      .list()
      .where(
          (entity) => entity is Directory && entity.path.contains('fmodstudio'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   âš ï¸  No FMOD SDK found in engines/android/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found: ${sdkDir.path.split(RegExp(r'[/\\]')).last}');

  // Copy native libraries to user's Android app
  final jniLibsDir =
      Directory('${projectRoot.path}/android/app/src/main/jniLibs');

  final architectures = ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'];
  var copied = 0;

  for (final arch in architectures) {
    final archDir = Directory('${jniLibsDir.path}/$arch');
    await archDir.create(recursive: true);

    // Copy core library
    final coreLib = File('${sdkDir.path}/api/core/lib/$arch/libfmod.so');
    if (await coreLib.exists()) {
      await coreLib.copy('${archDir.path}/libfmod.so');
      copied++;
    }

    // Copy studio library
    final studioLib =
        File('${sdkDir.path}/api/studio/lib/$arch/libfmodstudio.so');
    if (await studioLib.exists()) {
      await studioLib.copy('${archDir.path}/libfmodstudio.so');
      copied++;
    }
  }

  if (copied > 0) {
    print(
        '   âœ“ Copied $copied native libraries to android/app/src/main/jniLibs/');
    return true;
  } else {
    print('   âš ï¸  No native libraries found');
    return false;
  }
}

Future<bool> setupIOS(Directory projectRoot, Directory enginesDir) async {
  print('\nðŸŽ Setting up iOS...');

  final iosSdkDir = Directory('${enginesDir.path}/ios');
  if (!await iosSdkDir.exists()) {
    print('   âš ï¸  ios/ not found in engines/');
    print('   Skipping iOS setup.');
    return false;
  }

  // Find FMOD SDK
  final sdkDirs = await iosSdkDir
      .list()
      .where((entity) =>
          entity is Directory && entity.path.contains('fmodstudioapi'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   âš ï¸  No FMOD SDK found in engines/ios/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found: ${sdkDir.path.split(RegExp(r'[/\\]')).last}');

  // Create FMOD directories in user's iOS project
  final fmodDir = Directory('${projectRoot.path}/ios/FMOD');
  final fmodDeviceDir = Directory('${fmodDir.path}/lib/device');
  final fmodSimDir = Directory('${fmodDir.path}/lib/simulator');
  final fmodIncludeDir = Directory('${fmodDir.path}/include');

  await fmodDeviceDir.create(recursive: true);
  await fmodSimDir.create(recursive: true);
  await fmodIncludeDir.create(recursive: true);

  // Copy static libraries
  final libs = [
    {'file': 'libfmod_iphoneos.a', 'dest': fmodDeviceDir, 'type': 'core'},
    {
      'file': 'libfmodstudio_iphoneos.a',
      'dest': fmodDeviceDir,
      'type': 'studio'
    },
    {'file': 'libfmod_iphonesimulator.a', 'dest': fmodSimDir, 'type': 'core'},
    {
      'file': 'libfmodstudio_iphonesimulator.a',
      'dest': fmodSimDir,
      'type': 'studio'
    },
  ];

  var libsCopied = 0;
  for (final lib in libs) {
    final type = lib['type'] as String;
    final srcPath = '${sdkDir.path}/api/$type/lib/${lib['file']}';
    final srcFile = File(srcPath);

    if (await srcFile.exists()) {
      final dest = lib['dest'] as Directory;
      await srcFile.copy('${dest.path}/${lib['file']}');
      libsCopied++;
    }
  }

  // Copy headers
  var headersCopied = 0;
  for (final type in ['core', 'studio']) {
    final incDir = Directory('${sdkDir.path}/api/$type/inc');
    if (await incDir.exists()) {
      await for (final entity in incDir.list()) {
        if (entity is File && entity.path.endsWith('.h')) {
          final fileName = entity.path.split(RegExp(r'[/\\]')).last;
          await entity.copy('${fmodIncludeDir.path}/$fileName');
          headersCopied++;
        }
      }
    }
  }

  if (libsCopied > 0 && headersCopied > 0) {
    print(
        '   âœ“ Copied $libsCopied libraries and $headersCopied headers to ios/FMOD/');
    return true;
  } else {
    print('   âš ï¸  Failed to copy libraries or headers');
    return false;
  }
}

Future<bool> setupMacOS(Directory projectRoot, Directory enginesDir) async {
  print('\nðŸ–¥ï¸  Setting up macOS...');

  final macosSdkDir = Directory('${enginesDir.path}/macos');
  if (!await macosSdkDir.exists()) {
    print('   âš ï¸  macos/ not found in engines/');
    print('   Skipping macOS setup.');
    return false;
  }

  // Find FMOD SDK
  final sdkDirs = await macosSdkDir
      .list()
      .where((entity) =>
          entity is Directory && entity.path.contains('fmodstudioapi'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   âš ï¸  No FMOD SDK found in engines/macos/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found: ${sdkDir.path.split(RegExp(r'[/\\]')).last}');

  // Create FMOD directories in user's macOS project
  final fmodDir = Directory('${projectRoot.path}/macos/FMOD');
  final fmodLibDir = Directory('${fmodDir.path}/lib');
  final fmodIncludeDir = Directory('${fmodDir.path}/include');

  await fmodLibDir.create(recursive: true);
  await fmodIncludeDir.create(recursive: true);

  // Copy dynamic libraries
  final dylibs = [
    {
      'src': '${sdkDir.path}/api/core/lib/libfmod.dylib',
      'name': 'libfmod.dylib'
    },
    {
      'src': '${sdkDir.path}/api/studio/lib/libfmodstudio.dylib',
      'name': 'libfmodstudio.dylib'
    },
  ];

  var libsCopied = 0;
  for (final lib in dylibs) {
    final srcFile = File(lib['src']!);
    if (await srcFile.exists()) {
      await srcFile.copy('${fmodLibDir.path}/${lib['name']}');
      libsCopied++;
    }
  }

  // Copy headers
  var headersCopied = 0;
  for (final type in ['core', 'studio']) {
    final incDir = Directory('${sdkDir.path}/api/$type/inc');
    if (await incDir.exists()) {
      await for (final entity in incDir.list()) {
        if (entity is File &&
            (entity.path.endsWith('.h') || entity.path.endsWith('.hpp'))) {
          final fileName = entity.path.split(RegExp(r'[/\\]')).last;
          await entity.copy('${fmodIncludeDir.path}/$fileName');
          headersCopied++;
        }
      }
    }
  }

  if (libsCopied > 0 && headersCopied > 0) {
    print(
        '   âœ“ Copied $libsCopied libraries and $headersCopied headers to macos/FMOD/');
    return true;
  } else {
    print('   âš ï¸  Failed to copy libraries or headers');
    return false;
  }
}

Future<bool> setupWindows(Directory projectRoot, Directory enginesDir) async {
  print('\nðŸªŸ Setting up Windows...');

  final windowsSdkDir = Directory('${enginesDir.path}/windows');
  if (!await windowsSdkDir.exists()) {
    print('   ⚠️  windows/ not found in engines/');
    print('   Skipping Windows setup.');
    print(
        '   To set up Windows: download the FMOD Engine installer from fmod.com,');
    print(
        '   run it, then copy the installed folder to engines/windows/fmodstudioapi*win/');
    return false;
  }

  // Find FMOD SDK
  final sdkDirs = await windowsSdkDir
      .list()
      .where((entity) =>
          entity is Directory && entity.path.contains('fmodstudioapi'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   ⚠️  No FMOD SDK found in engines/windows/');
    print(
        '   The folder must contain a subfolder named fmodstudioapi* with the SDK contents.');
    print(
        '   Windows SDK comes as an .exe installer - run it first, then copy the');
    print(
        '   installed folder (e.g. from C:\\Program Files (x86)\\FMOD SoundSystem\\)');
    print('   into engines/windows/.');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found: ${sdkDir.path.split(RegExp(r'[/\\]')).last}');

  // Create FMOD directories in user's Windows project
  final fmodDir = Directory('${projectRoot.path}/windows/FMOD');
  final fmodLibDir = Directory('${fmodDir.path}/lib');
  final fmodDllDir = Directory('${fmodDir.path}/dll');
  final fmodIncludeDir = Directory('${fmodDir.path}/include');

  await fmodLibDir.create(recursive: true);
  await fmodDllDir.create(recursive: true);
  await fmodIncludeDir.create(recursive: true);

  var copied = 0;

  // Copy import libraries (.lib) - x64
  final libs = [
    {
      'src': '${sdkDir.path}/api/core/lib/x64/fmod_vc.lib',
      'name': 'fmod_vc.lib'
    },
    {
      'src': '${sdkDir.path}/api/studio/lib/x64/fmodstudio_vc.lib',
      'name': 'fmodstudio_vc.lib'
    },
  ];

  for (final lib in libs) {
    final srcFile = File(lib['src']!);
    if (await srcFile.exists()) {
      await srcFile.copy('${fmodLibDir.path}/${lib['name']}');
      copied++;
    }
  }

  // Copy DLLs
  final dlls = [
    {'src': '${sdkDir.path}/api/core/lib/x64/fmod.dll', 'name': 'fmod.dll'},
    {
      'src': '${sdkDir.path}/api/studio/lib/x64/fmodstudio.dll',
      'name': 'fmodstudio.dll'
    },
  ];

  for (final dll in dlls) {
    final srcFile = File(dll['src']!);
    if (await srcFile.exists()) {
      await srcFile.copy('${fmodDllDir.path}/${dll['name']}');
      copied++;
    }
  }

  // Copy headers
  var headersCopied = 0;
  for (final type in ['core', 'studio']) {
    final incDir = Directory('${sdkDir.path}/api/$type/inc');
    if (await incDir.exists()) {
      await for (final entity in incDir.list()) {
        if (entity is File &&
            (entity.path.endsWith('.h') || entity.path.endsWith('.hpp'))) {
          final fileName = entity.path.split(RegExp(r'[/\\]')).last;
          await entity.copy('${fmodIncludeDir.path}/$fileName');
          headersCopied++;
        }
      }
    }
  }

  if (copied > 0 && headersCopied > 0) {
    print(
        '   âœ“ Copied $copied libraries/DLLs and $headersCopied headers to windows/FMOD/');
    return true;
  } else {
    print('   âš ï¸  Failed to copy libraries or headers');
    return false;
  }
}

Future<bool> setupWeb(Directory projectRoot, Directory enginesDir) async {
  print('\nðŸŒ Setting up Web...');

  final html5SdkDir = Directory('${enginesDir.path}/html5');
  if (!await html5SdkDir.exists()) {
    print('   âš ï¸  html5/ not found in engines/');
    print('   Skipping Web setup.');
    return false;
  }

  // Find FMOD SDK
  final sdkDirs = await html5SdkDir
      .list()
      .where(
          (entity) => entity is Directory && entity.path.contains('fmodstudio'))
      .toList();

  if (sdkDirs.isEmpty) {
    print('   âš ï¸  No FMOD SDK found in engines/html5/');
    return false;
  }

  final sdkDir = sdkDirs.first as Directory;
  print('   Found: ${sdkDir.path.split(RegExp(r'[/\\]')).last}');

  // Copy to user's web directory
  final webFmodDir = Directory('${projectRoot.path}/web/fmod');
  await webFmodDir.create(recursive: true);

  final files = [
    {'src': '${sdkDir.path}/api/core/lib/wasm/fmod.js', 'name': 'fmod.js'},
    {'src': '${sdkDir.path}/api/core/lib/wasm/fmod.wasm', 'name': 'fmod.wasm'},
    {
      'src': '${sdkDir.path}/api/studio/lib/wasm/fmodstudio.js',
      'name': 'fmodstudio.js'
    },
    {
      'src': '${sdkDir.path}/api/studio/lib/wasm/fmodstudio.wasm',
      'name': 'fmodstudio.wasm'
    },
  ];

  var copied = 0;
  for (final fileInfo in files) {
    final file = File(fileInfo['src']!);
    if (await file.exists()) {
      await file.copy('${webFmodDir.path}/${fileInfo['name']}');
      copied++;
    }
  }

  if (copied > 0) {
    print('   âœ“ Copied $copied files to web/fmod/');

    // Check if index.html needs updating
    final indexHtml = File('${projectRoot.path}/web/index.html');
    if (await indexHtml.exists()) {
      final content = await indexHtml.readAsString();
      if (!content.contains('fmod/fmodstudio.js')) {
        print(
            '\n   ðŸ“ NOTE: Add this to your web/index.html <head> section:');
        print('      <script src="fmod/fmodstudio.js" defer></script>\n');
      }
    }

    return true;
  } else {
    print('   âš ï¸  No WASM/JS files found');
    return false;
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    if (entity is Directory) {
      final newDir = Directory(
          '${destination.path}/${entity.path.split(RegExp(r'[/\\]')).last}');
      await _copyDirectory(entity, newDir);
    } else if (entity is File) {
      await entity.copy(
          '${destination.path}/${entity.path.split(RegExp(r'[/\\]')).last}');
    }
  }
}
