import 'dart:async';
import 'dart:math';

import 'package:backstage/backstage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Backstage with comprehensive configuration
  await Backstage().init(const BackstageConfig(
    // Core logging features
    capturePrint: true,
    captureFlutterErrors: true,
    captureZoneErrors: false, // Simplified for demo - avoid zone complexity
    enabledByDefault: kDebugMode, // Auto-enable in debug mode
    persistEnabled: true,

    // Advanced features
    captureNetworkRequests: true,
    capturePerformanceMetrics: true,
    enableExport: true,
    persistLogs: false, // Keep it simple for demo

    // Security configuration
    requireBiometric: false, // Set to true in production
    securityConfig: SecurityConfig(
      sanitizePatterns: ['password=.*', 'token=.*', 'secret=.*'],
      maxFailedAttempts: 3,
    ),

    // Network monitoring configuration
    networkConfig: NetworkConfig(
      captureHeaders: true,
      captureErrors: true,
      maxBodySize: 1024 * 10, // 10KB max body size
    ),

    // Performance monitoring configuration - optimized for demo to reduce noise
    performanceConfig: PerformanceConfig(
      trackMemoryUsage: true,
      trackFPS: true,
      trackCPUUsage: false, // Disabled for demo to reduce overhead
      trackBatteryStatus: false, // Disabled for demo
      trackConnectivity: false, // Disabled for demo
      collectionIntervalMs: 5000, // Collect less frequently (every 5 seconds)
      frameTimeWarningThresholdMs: 100, // Very lenient threshold (100ms = 10 FPS)
      memoryWarningThresholdMB: 300, // High threshold to reduce noise
      memoryCriticalThresholdMB: 500, // Very high threshold
      maxDataPoints: 50, // Limit data retention for demo
    ),

    // Export configuration
    exportConfig: ExportConfig(
      allowSharing: true,
      includeMetadata: true,
      includeSystemInfo: kDebugMode, // Only in debug mode
      maxEntriesPerExport: 5000,
      compressExports: true,
      autoCleanupExports: true,
      exportRetentionDays: 7,
    ),

    // Storage configuration - using memory for simplicity in demo
    storageConfig: StorageConfig(
      backend: StorageBackend.memory,
      maxLogEntries: 1000,
      retentionDays: 1,
    ),

    // UI configuration
    uiConfig: UIConfig(
      layout: ConsoleLayout.tabbed,
      defaultPosition: DefaultPosition.topRight,
      minPanelWidth: 350,
      maxPanelWidth: 700,
      isResizable: true,
      enableAnimations: true,
      showPerformanceOverlay: kDebugMode,
      panelElevation: 8.0,
      borderRadius: 12.0,
      panelOpacity: 0.95,
    ),

    // Theme configuration
    theme: BackstageTheme.system,
    themeConfig: ThemeConfig(
      primaryColor: Colors.blue,
      fontFamily: 'monospace',
    ),
  ));

  // Run app - zone error capture is handled internally by Backstage
  runApp(const BackstageExampleApp());
}

class BackstageExampleApp extends StatelessWidget {
  const BackstageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstage Feature Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BackstageOverlay(
        child: BackstageEntryGate(
          passcode: kDebugMode ? null : '1234',
          child: const FeatureDemoHome(),
        ),
      ),
    );
  }
}

class FeatureDemoHome extends StatefulWidget {
  const FeatureDemoHome({super.key});

  @override
  State<FeatureDemoHome> createState() => _FeatureDemoHomeState();
}

class _FeatureDemoHomeState extends State<FeatureDemoHome>
    with TickerProviderStateMixin {
  final _dio = Dio();
  Timer? _performanceTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _setupNetworkInterceptor();
    _startPerformanceDemo();
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupNetworkInterceptor() {
    // Network requests will be automatically captured by Backstage
    // No manual interceptor setup needed
  }

  void _startPerformanceDemo() {
    // Simulate some performance activity
    _performanceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _simulatePerformanceActivity();
    });
  }

  void _simulatePerformanceActivity() {
    // Simulate some work to generate performance data
    final random = Random();
    final list = List.generate(random.nextInt(1000) + 100, (i) => i * i);
    list.sort();

    // Log performance activity
    Backstage.I.logger.d(
      'Simulated performance activity: processed ${list.length} items',
      tag: 'performance',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backstage Feature Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bug_report), text: 'Logging'),
            Tab(icon: Icon(Icons.network_check), text: 'Network'),
            Tab(icon: Icon(Icons.speed), text: 'Performance'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.share), text: 'Export'),
            Tab(icon: Icon(Icons.info), text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoggingDemo(),
          _buildNetworkDemo(),
          _buildPerformanceDemo(),
          _buildSecurityDemo(),
          _buildExportDemo(),
          _buildAboutTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Backstage.I.setEnabled(true),
        icon: const Icon(Icons.developer_mode),
        label: const Text('Open Backstage'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildLoggingDemo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Logging Features Demo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap the activation area below 5 times or long-press to open Backstage console:',
        ),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              '🎯 TAP HERE 5× OR LONG-PRESS\nto activate Backstage',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _emitSampleLogs,
              icon: const Icon(Icons.article),
              label: const Text('Sample Logs'),
            ),
            ElevatedButton.icon(
              onPressed: _emitErrorWithStackTrace,
              icon: const Icon(Icons.error),
              label: const Text('Error + Stack'),
            ),
            ElevatedButton.icon(
              onPressed: _emitPrintMessages,
              icon: const Icon(Icons.print),
              label: const Text('Print Messages'),
            ),
            ElevatedButton.icon(
              onPressed: _triggerFlutterError,
              icon: const Icon(Icons.warning),
              label: const Text('Flutter Error'),
            ),
            ElevatedButton.icon(
              onPressed: _triggerAsyncError,
              icon: const Icon(Icons.timer),
              label: const Text('Async Error (Demo)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkDemo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Network Monitoring Demo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'These buttons will make HTTP requests that are automatically captured by Backstage:',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _makeSuccessfulRequest,
              icon: const Icon(Icons.check_circle),
              label: const Text('Successful GET'),
            ),
            ElevatedButton.icon(
              onPressed: _makePostRequest,
              icon: const Icon(Icons.send),
              label: const Text('POST with Body'),
            ),
            ElevatedButton.icon(
              onPressed: _makeFailedRequest,
              icon: const Icon(Icons.error),
              label: const Text('Failed Request'),
            ),
            ElevatedButton.icon(
              onPressed: _makeSlowRequest,
              icon: const Icon(Icons.access_time),
              label: const Text('Slow Request'),
            ),
            ElevatedButton.icon(
              onPressed: _makeMultipleRequests,
              icon: const Icon(Icons.multiple_stop),
              label: const Text('Multiple Requests'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceDemo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Performance Monitoring Demo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📈 Performance Noise Reduction',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'This demo uses throttled performance monitoring:\n'
                  '• Frame warnings limited to every 5 seconds\n'
                  '• Lenient thresholds (100ms = 10 FPS)\n'
                  '• Reduced collection frequency (5s intervals)\n'
                  '• Aggregated janky frame reporting\n'
                  '• Optional: Set trackFPS: false to disable entirely',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Performance metrics are automatically collected. These buttons simulate various performance scenarios:',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _simulateMemoryUsage,
              icon: const Icon(Icons.memory),
              label: const Text('Memory Usage'),
            ),
            ElevatedButton.icon(
              onPressed: _simulateHeavyComputation,
              icon: const Icon(Icons.calculate),
              label: const Text('Heavy Computation'),
            ),
            ElevatedButton.icon(
              onPressed: _simulateFrameDrops,
              icon: const Icon(Icons.videocam_off),
              label: const Text('Frame Drops'),
            ),
            ElevatedButton.icon(
              onPressed: _checkBatteryStatus,
              icon: const Icon(Icons.battery_std),
              label: const Text('Battery Info'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityDemo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Security Features Demo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Security features include data sanitization and access control:',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _logSensitiveData,
              icon: const Icon(Icons.security),
              label: const Text('Sensitive Data (Sanitized)'),
            ),
            ElevatedButton.icon(
              onPressed: _testAccessControl,
              icon: const Icon(Icons.lock),
              label: const Text('Access Control'),
            ),
            ElevatedButton.icon(
              onPressed: _logSecurityEvent,
              icon: const Icon(Icons.shield),
              label: const Text('Security Event'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportDemo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Export & Sharing Demo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Export logs in various formats and share them:',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _exportLogs('json'),
              icon: const Icon(Icons.code),
              label: const Text('Export JSON'),
            ),
            ElevatedButton.icon(
              onPressed: () => _exportLogs('csv'),
              icon: const Icon(Icons.table_chart),
              label: const Text('Export CSV'),
            ),
            ElevatedButton.icon(
              onPressed: () => _exportLogs('html'),
              icon: const Icon(Icons.web),
              label: const Text('Export HTML'),
            ),
            ElevatedButton.icon(
              onPressed: () => _exportLogs('text'),
              icon: const Icon(Icons.text_fields),
              label: const Text('Export Text'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'About Backstage',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Features Enabled:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildFeatureStatus('Core Logging', true),
                _buildFeatureStatus(
                    'Network Monitoring', Backstage.I.networkService != null),
                _buildFeatureStatus('Performance Metrics',
                    Backstage.I.performanceService != null),
                _buildFeatureStatus(
                    'Security Features', Backstage.I.securityService != null),
                _buildFeatureStatus(
                    'Export Capability', Backstage.I.exportService != null),
                _buildFeatureStatus(
                    'Enhanced Logger', Backstage.I.enhancedLogger != null),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How to Use:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Tap the activation area 5 times or long-press'),
                const Text(
                    '2. Enter passcode if required (1234 in release mode)'),
                const Text(
                    '3. Browse tabs: Logs, Network, Performance, Export'),
                const Text(
                    '4. Use search and filters to find specific entries'),
                const Text('5. Export data in various formats for analysis'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showSystemInfo,
          icon: const Icon(Icons.info),
          label: const Text('Show System Info'),
        ),
      ],
    );
  }

  Widget _buildFeatureStatus(String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  // Logging demo methods
  void _emitSampleLogs() {
    final logger = Backstage.I.logger;
    logger.d('Debug: This is a debug message', tag: 'demo');
    logger.i('Info: Application started successfully', tag: 'demo');
    logger.w('Warning: This is a warning message', tag: 'demo');
    logger.e('Error: Something went wrong', tag: 'demo');
  }

  void _emitErrorWithStackTrace() {
    try {
      throw Exception('Intentional demo exception for stack trace');
    } catch (e, stackTrace) {
      Backstage.I.logger.e(
        'Caught exception: $e',
        tag: 'error_demo',
        st: stackTrace,
      );
    }
  }

  void _emitPrintMessages() {
    print('This is a regular print message');
    debugPrint('This is a debugPrint message');
  }

  void _triggerFlutterError() {
    // Trigger a Flutter framework error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      throw FlutterError('Demo Flutter framework error');
    });
  }

  void _triggerAsyncError() {
    // Demonstrate how async errors would be handled
    // Note: Zone error capture is disabled in this demo for simplicity
    Backstage.I.logger.e(
      'Demo: This would be an async error caught by zone error capture',
      tag: 'async_demo',
    );
  }

  // Network demo methods
  Future<void> _makeSuccessfulRequest() async {
    try {
      final response =
          await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      Backstage.I.logger
          .i('Successful request: ${response.statusCode}', tag: 'network');
    } catch (e) {
      Backstage.I.logger.e('Request failed: $e', tag: 'network');
    }
  }

  Future<void> _makePostRequest() async {
    try {
      final data = {
        'title': 'Backstage Demo Post',
        'body': 'This is a demo POST request from Backstage',
        'userId': 1,
      };
      final response = await _dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: data,
      );
      Backstage.I.logger
          .i('POST request: ${response.statusCode}', tag: 'network');
    } catch (e) {
      Backstage.I.logger.e('POST request failed: $e', tag: 'network');
    }
  }

  Future<void> _makeFailedRequest() async {
    try {
      await _dio.get('https://httpstat.us/404');
    } catch (e) {
      Backstage.I.logger.e('Expected 404 error: $e', tag: 'network');
    }
  }

  Future<void> _makeSlowRequest() async {
    try {
      final response = await _dio.get('https://httpstat.us/200?sleep=3000');
      Backstage.I.logger
          .i('Slow request completed: ${response.statusCode}', tag: 'network');
    } catch (e) {
      Backstage.I.logger.e('Slow request failed: $e', tag: 'network');
    }
  }

  Future<void> _makeMultipleRequests() async {
    final futures = List.generate(5, (i) async {
      try {
        final response = await _dio
            .get('https://jsonplaceholder.typicode.com/posts/${i + 1}');
        Backstage.I.logger
            .d('Request $i completed: ${response.statusCode}', tag: 'network');
      } catch (e) {
        Backstage.I.logger.e('Request $i failed: $e', tag: 'network');
      }
    });

    await Future.wait(futures);
    Backstage.I.logger.i('All multiple requests completed', tag: 'network');
  }

  // Performance demo methods
  void _simulateMemoryUsage() {
    // Simulate memory allocation
    final largeList = List.generate(100000, (i) => 'Item $i ' * 10);
    Backstage.I.logger.i(
      'Simulated memory usage: ${largeList.length} items allocated',
      tag: 'performance',
    );
    // Let GC clean up
    largeList.clear();
  }

  void _simulateHeavyComputation() {
    final stopwatch = Stopwatch()..start();

    // Heavy computation
    var result = 0;
    for (int i = 0; i < 1000000; i++) {
      result += i * i;
    }

    stopwatch.stop();
    Backstage.I.logger.i(
      'Heavy computation completed in ${stopwatch.elapsedMilliseconds}ms (result: $result)',
      tag: 'performance',
    );
  }

  void _simulateFrameDrops() {
    // Simulate frame drops by doing heavy work on main thread
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < 100) {
      // Busy wait to block main thread
    }
    Backstage.I.logger
        .w('Simulated frame drops (100ms block)', tag: 'performance');
  }

  void _checkBatteryStatus() {
    Backstage.I.logger.i('Battery status check requested', tag: 'performance');
    // The actual battery info will be collected by the performance service
  }

  // Security demo methods
  void _logSensitiveData() {
    // This data should be sanitized according to the security config
    Backstage.I.logger.w(
      'User login attempt: password=secret123 token=abc123xyz secret=confidential',
      tag: 'security',
    );
    Backstage.I.logger.i(
      'Login successful for user: john.doe@example.com',
      tag: 'security',
    );
  }

  void _testAccessControl() {
    Backstage.I.logger
        .i('Access control test: checking permissions', tag: 'security');
    // Simulate access control check
    final hasAccess = Random().nextBool();
    if (hasAccess) {
      Backstage.I.logger.i('Access granted to admin panel', tag: 'security');
    } else {
      Backstage.I.logger
          .w('Access denied: insufficient privileges', tag: 'security');
    }
  }

  void _logSecurityEvent() {
    final events = [
      'Suspicious login attempt from unknown device',
      'Rate limit exceeded for API endpoint',
      'Invalid token provided in request',
      'Potential XSS attempt detected',
      'Failed biometric authentication',
    ];
    final event = events[Random().nextInt(events.length)];
    Backstage.I.logger.e('Security event: $event', tag: 'security');
  }

  // Export demo methods
  Future<void> _exportLogs(String formatName) async {
    if (Backstage.I.exportService == null) {
      Backstage.I.logger.w('Export service not available', tag: 'export');
      return;
    }

    try {
      Backstage.I.logger.i(
        'Export functionality demo - would export logs in $formatName format',
        tag: 'export',
      );

      // Note: Actual export functionality would use the console's built-in export features
      // This is just a demo of the logging capabilities
    } catch (e) {
      Backstage.I.logger.e('Export demo failed: $e', tag: 'export');
    }
  }

  void _showSystemInfo() {
    final info = {
      'Platform': Theme.of(context).platform.name,
      'Debug Mode': kDebugMode.toString(),
      'Release Mode': kReleaseMode.toString(),
      'Profile Mode': kProfileMode.toString(),
      'Is Web': kIsWeb.toString(),
    };

    for (final entry in info.entries) {
      Backstage.I.logger.i('${entry.key}: ${entry.value}', tag: 'system_info');
    }
  }
}
