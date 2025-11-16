import 'package:flutter/material.dart';
import 'package:fmod_flutter/fmod_flutter.dart';

void main() {
  runApp(const FmodExampleApp());
}

class FmodExampleApp extends StatelessWidget {
  const FmodExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMOD Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FmodExampleHome(),
    );
  }
}

class FmodExampleHome extends StatefulWidget {
  const FmodExampleHome({super.key});

  @override
  State<FmodExampleHome> createState() => _FmodExampleHomeState();
}

class _FmodExampleHomeState extends State<FmodExampleHome> {
  final FmodService _fmod = FmodService();
  bool _isInitialized = false;
  bool _isLoading = true;
  String _statusMessage = 'Initializing FMOD...';

  // Track playing events
  final Set<String> _playingEvents = {};

  // Sample event paths - update these to match your FMOD project
  final List<String> _musicEvents = [
    'event:/Music/MainTheme',
    'event:/Music/BattleTheme',
    'event:/Music/AmbientTheme',
  ];

  final List<String> _sfxEvents = [
    'event:/SFX/Jump',
    'event:/SFX/Click',
    'event:/SFX/Explosion',
    'event:/SFX/TrapHit',
    'event:/SFX/Victory',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFmod();
  }

  Future<void> _initializeFmod() async {
    setState(() {
      _statusMessage = 'Initializing FMOD system...';
    });

    try {
      // Initialize FMOD
      final initialized = await _fmod.initialize();

      if (!initialized) {
        setState(() {
          _statusMessage =
              'Failed to initialize FMOD. See console for details.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Loading FMOD banks...';
      });

      // Load banks
      final banksLoaded = await _fmod.loadBanks([
        'assets/audio/Master.bank',
        'assets/audio/Master.strings.bank',
        'assets/audio/Music.bank',
        'assets/audio/SFX.bank',
      ]);

      if (!banksLoaded) {
        setState(() {
          _statusMessage =
              'Failed to load FMOD banks. See console for details.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _statusMessage = 'FMOD ready! Try playing some events.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playEvent(String eventPath) async {
    if (!_isInitialized) return;

    await _fmod.playEvent(eventPath);
    setState(() {
      _playingEvents.add(eventPath);
      _statusMessage = 'Playing: $eventPath';
    });

    // Auto-remove from playing set after a delay (simulated)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _playingEvents.remove(eventPath);
        });
      }
    });
  }

  Future<void> _stopEvent(String eventPath) async {
    if (!_isInitialized) return;

    await _fmod.stopEvent(eventPath);
    setState(() {
      _playingEvents.remove(eventPath);
      _statusMessage = 'Stopped: $eventPath';
    });
  }

  @override
  void dispose() {
    _fmod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              isDarkMode
                  ? 'assets/images/FMOD Logo White - Transparent Background.png'
                  : 'assets/images/FMOD Logo Black - Transparent Background.png',
              height: 28,
            ),
            const SizedBox(width: 12),
            const Text('Flutter Example'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // FMOD Logo
                  Image.asset(
                    isDarkMode
                        ? 'assets/images/FMOD Logo White - Transparent Background.png'
                        : 'assets/images/FMOD Logo Black - Transparent Background.png',
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          Card(
            color: _isInitialized ? Colors.green.shade900 : Colors.red.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isInitialized ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isInitialized
                              ? 'FMOD Initialized'
                              : 'FMOD Not Ready',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (!_isInitialized) ...[
            _buildSetupInstructions(),
          ] else ...[
            // Music Events Section
            _buildSection(
              title: '🎵 Music Events',
              events: _musicEvents,
              color: Colors.purple,
            ),

            const SizedBox(height: 24),

            // SFX Events Section
            _buildSection(
              title: '🔊 Sound Effects',
              events: _sfxEvents,
              color: Colors.orange,
            ),

            const SizedBox(height: 24),

            // Info Card
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Event paths must match your FMOD Studio project\n'
                      '• Update event lists in main.dart to match your events\n'
                      '• Check console logs for FMOD debug messages\n'
                      '• Test on real devices for best results',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FMOD Branding Footer
            Center(
              child: Column(
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/FMOD Logo White - Transparent Background.png'
                        : 'assets/images/FMOD Logo Black - Transparent Background.png',
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Flutter Plugin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> events,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        ...events.map((eventPath) => _buildEventButton(eventPath, color)),
      ],
    );
  }

  Widget _buildEventButton(String eventPath, Color color) {
    final isPlaying = _playingEvents.contains(eventPath);
    final eventName = eventPath.split('/').last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _playEvent(eventPath),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaying
                    ? color
                    : color.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPlaying ? Icons.volume_up : Icons.play_arrow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          eventPath,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isPlaying) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _stopEvent(eventPath),
              icon: const Icon(Icons.stop),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupInstructions() {
    return Column(
      children: [
        // Main alert card
        Card(
          color: Colors.orange.shade900,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'FMOD Engine Not Configured',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The FMOD Engine native libraries are required to run this example.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick setup card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Quick Setup (Recommended)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSetupStep(
                  number: '1',
                  title: 'Download FMOD Engine',
                  description:
                      'Visit fmod.com/download and download FMOD Engine for your target platforms (iOS, Android, HTML5)',
                  icon: Icons.download,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildSetupStep(
                  number: '2',
                  title: 'Extract to engines/ directory',
                  description:
                      'Extract the downloaded SDKs to the engines/ folder in the plugin root. See engines/README.md for the expected structure.',
                  icon: Icons.folder,
                  color: Colors.purple,
                ),
                const SizedBox(height: 12),
                _buildSetupStep(
                  number: '3',
                  title: 'Run the setup script',
                  description:
                      'In the terminal, run:\n\ncd <plugin_root>\ndart tool/setup_fmod.dart\n\n(Replace <plugin_root> with your plugin path)',
                  icon: Icons.terminal,
                  color: Colors.green,
                  isCode: true,
                ),
                const SizedBox(height: 12),
                _buildSetupStep(
                  number: '4',
                  title: 'Rebuild the app',
                  description:
                      'Run flutter clean and rebuild:\n\nflutter clean\nflutter run',
                  icon: Icons.build,
                  color: Colors.orange,
                  isCode: true,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Manual setup card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.construction, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Manual Setup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'If you prefer manual setup or the script doesn\'t work, follow the detailed instructions in:',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.description, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '../FMOD_SETUP.md',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Important notes card
        Card(
          color: Colors.blue.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Important Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '• You need a free FMOD account to download the engine',
                ),
                _buildInfoRow(
                  '• FMOD is free for indie games (<\$200k revenue/year)',
                ),
                _buildInfoRow(
                  '• The setup script automatically copies all required files',
                ),
                _buildInfoRow('• Make sure to rebuild completely after setup'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isCode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                isCode
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black26
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      )
                    : Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
