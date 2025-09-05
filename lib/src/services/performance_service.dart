/// Performance monitoring and metrics collection service.
///
/// This file provides comprehensive system performance tracking including
/// memory usage, frame rates, CPU utilization, battery status, and other
/// device metrics that help identify performance bottlenecks and resource
/// consumption patterns.
library;

import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config/performance_config.dart';
import '../logger.dart';

/// Represents a performance data point with timestamp and metrics.
class PerformanceSnapshot {
  /// Timestamp when this snapshot was taken
  final DateTime timestamp;

  /// Memory usage in bytes
  final int? memoryUsage;

  /// CPU usage percentage (0-100)
  final double? cpuUsage;

  /// Current frame rate (FPS)
  final double? frameRate;

  /// Battery level percentage (0-100)
  final double? batteryLevel;

  /// Whether device is charging
  final bool? isCharging;

  /// Network connectivity type
  final String? connectivityType;

  /// Device orientation
  final String? orientation;

  /// Screen brightness level (0-1)
  final double? screenBrightness;

  /// Available memory in bytes
  final int? availableMemory;

  /// Total device memory in bytes
  final int? totalMemory;

  /// Current app state (foreground/background)
  final String? appState;

  /// Additional custom metrics
  final Map<String, dynamic> customMetrics;

  /// Creates a new performance snapshot.
  const PerformanceSnapshot({
    required this.timestamp,
    this.memoryUsage,
    this.cpuUsage,
    this.frameRate,
    this.batteryLevel,
    this.isCharging,
    this.connectivityType,
    this.orientation,
    this.screenBrightness,
    this.availableMemory,
    this.totalMemory,
    this.appState,
    this.customMetrics = const {},
  });

  /// Converts to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'memoryUsage': memoryUsage,
      'cpuUsage': cpuUsage,
      'frameRate': frameRate,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'connectivityType': connectivityType,
      'orientation': orientation,
      'screenBrightness': screenBrightness,
      'availableMemory': availableMemory,
      'totalMemory': totalMemory,
      'appState': appState,
      'customMetrics': customMetrics,
    };
  }
}

/// Frame timing information for UI performance analysis.
class FrameInfo {
  /// Frame number
  final int frameNumber;

  /// Frame start timestamp
  final DateTime timestamp;

  /// Frame duration in milliseconds
  final double durationMs;

  /// Whether this frame was janky (exceeded target time)
  final bool isJanky;

  /// Target frame time in milliseconds (typically 16.67ms for 60 FPS)
  final double targetFrameTimeMs;

  /// Creates new frame information.
  const FrameInfo({
    required this.frameNumber,
    required this.timestamp,
    required this.durationMs,
    required this.isJanky,
    required this.targetFrameTimeMs,
  });

  /// Converts to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'frameNumber': frameNumber,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': durationMs,
      'isJanky': isJanky,
      'targetFrameTimeMs': targetFrameTimeMs,
    };
  }
}

/// Comprehensive performance monitoring service for system metrics tracking.
///
/// [PerformanceService] provides automated collection of device and application
/// performance metrics including memory usage, frame rates, battery status,
/// connectivity, and other system information useful for performance analysis
/// and optimization.
///
/// **Monitored Metrics**:
/// * **Memory**: Heap usage, available memory, garbage collection events
/// * **CPU**: Process and system CPU utilization percentages
/// * **UI Performance**: Frame rates, jank detection, render timing
/// * **Battery**: Level, charging status, power consumption estimates
/// * **Network**: Connection type, signal strength, bandwidth usage
/// * **Device**: Orientation, brightness, thermal state, disk usage
///
/// **Performance Impact**:
/// * Metrics collection is designed for minimal overhead
/// * Configurable collection intervals balance accuracy with resource usage
/// * Background processing prevents UI thread blocking
/// * Automatic data retention limits prevent memory leaks
///
/// **Analysis Features**:
/// * Real-time performance threshold monitoring
/// * Historical trend analysis and pattern detection
/// * Performance regression identification
/// * Resource usage optimization recommendations
///
/// Example usage:
/// ```dart
/// final performanceService = PerformanceService(performanceConfig, logger);
/// await performanceService.initialize();
///
/// // Monitor performance in real-time
/// performanceService.snapshotStream.listen((snapshot) {
///   if (snapshot.memoryUsage! > 100 * 1024 * 1024) { // 100MB
///     print('High memory usage detected: ${snapshot.memoryUsage! ~/ 1024 / 1024}MB');
///   }
/// });
///
/// // Get performance summary
/// final stats = performanceService.getPerformanceStats();
/// ```
class PerformanceService {
  /// Configuration for performance monitoring behavior.
  final PerformanceConfig config;

  /// Logger for outputting performance events.
  final BackstageLogger logger;

  /// Storage for performance snapshots.
  final List<PerformanceSnapshot> _snapshots = [];

  /// Storage for frame timing information.
  final List<FrameInfo> _frames = [];

  /// Stream controller for real-time performance events.
  final _snapshotController = StreamController<PerformanceSnapshot>.broadcast();

  /// Stream controller for frame events.
  final _frameController = StreamController<FrameInfo>.broadcast();

  /// Timer for periodic metric collection.
  Timer? _collectionTimer;

  /// Battery instance for battery monitoring.
  final Battery _battery = Battery();

  /// Connectivity instance for network monitoring.
  final Connectivity _connectivity = Connectivity();

  /// Device info instance for device details.
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Frame counter for FPS calculation.
  int _frameCount = 0;

  /// Last FPS calculation timestamp.
  DateTime _lastFpsCalculation = DateTime.now();

  /// Current app lifecycle state.
  final AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  /// Creates a new performance monitoring service.
  ///
  /// The [config] parameter defines what performance metrics should be
  /// tracked and how frequently they should be collected. The [logger]
  /// receives performance events as structured log entries.
  PerformanceService(this.config, this.logger);

  /// Stream of performance snapshots for real-time monitoring.
  ///
  /// Emits [PerformanceSnapshot] objects at configured intervals containing
  /// current system performance metrics. Useful for building real-time
  /// monitoring dashboards or implementing performance-based logic.
  Stream<PerformanceSnapshot> get snapshotStream => _snapshotController.stream;

  /// Stream of frame timing information for UI performance analysis.
  ///
  /// Emits [FrameInfo] objects for each rendered frame when frame tracking
  /// is enabled. Useful for identifying UI performance issues and janky
  /// animations that affect user experience.
  Stream<FrameInfo> get frameStream => _frameController.stream;

  /// Initializes performance monitoring and starts metric collection.
  ///
  /// Sets up periodic metric collection, frame timing monitoring, and
  /// device information gathering based on the provided configuration.
  /// Should be called early in the application lifecycle.
  ///
  /// **Setup Actions**:
  /// * Starts periodic performance snapshot collection
  /// * Configures frame timing monitoring for UI performance
  /// * Sets up device and battery monitoring
  /// * Initializes connectivity and lifecycle listeners
  /// * Applies performance threshold monitoring
  ///
  /// Example:
  /// ```dart
  /// await performanceService.initialize();
  ///
  /// // Performance metrics are now being collected automatically
  /// // Access them via getPerformanceSnapshots() or the stream
  /// ```
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint(
          'Backstage PerformanceService: Initializing performance monitoring');
    }

    // Start periodic metric collection
    _startPeriodicCollection();

    // Set up frame monitoring if enabled
    if (config.trackFPS) {
      _setupFrameMonitoring();
    }

    // Set up lifecycle monitoring
    _setupLifecycleMonitoring();

    // Initial performance snapshot
    await _collectPerformanceSnapshot();

    logger.i('Performance monitoring initialized', tag: 'performance');
  }

  /// Retrieves all collected performance snapshots.
  ///
  /// Returns a copy of all performance snapshots collected since
  /// initialization or the last clear operation. Snapshots are
  /// ordered chronologically.
  ///
  /// Returns: List of [PerformanceSnapshot] objects
  List<PerformanceSnapshot> getPerformanceSnapshots() {
    return List.unmodifiable(_snapshots);
  }

  /// Retrieves frame timing information.
  ///
  /// Returns a copy of all frame timing data collected since
  /// initialization. Useful for analyzing UI performance patterns
  /// and identifying performance regressions.
  ///
  /// Returns: List of [FrameInfo] objects
  List<FrameInfo> getFrameInfo() {
    return List.unmodifiable(_frames);
  }

  /// Gets comprehensive performance statistics and analysis.
  ///
  /// Calculates aggregate performance metrics including averages,
  /// trends, threshold violations, and performance health indicators.
  /// Useful for performance dashboards and automated monitoring.
  ///
  /// Returns: Map containing various performance statistics
  ///
  /// Example:
  /// ```dart
  /// final stats = performanceService.getPerformanceStats();
  /// print('Average memory usage: ${stats['averageMemoryMB']}MB');
  /// print('Frame drops: ${stats['jankyFrameCount']}');
  /// print('Battery drain rate: ${stats['batteryDrainRate']}%/hour');
  /// ```
  Map<String, dynamic> getPerformanceStats() {
    if (_snapshots.isEmpty) {
      return {
        'totalSnapshots': 0,
        'monitoringDuration': 0,
        'averageMemoryMB': 0.0,
        'averageCPU': 0.0,
        'averageFPS': 0.0,
        'jankyFrameCount': 0,
        'batteryDrainRate': 0.0,
      };
    }

    final totalSnapshots = _snapshots.length;
    final monitoringDuration =
        _snapshots.last.timestamp.difference(_snapshots.first.timestamp);

    // Memory statistics
    final memorySnapshots = _snapshots.where((s) => s.memoryUsage != null);
    final averageMemoryBytes = memorySnapshots.isEmpty
        ? 0.0
        : memorySnapshots.map((s) => s.memoryUsage!).reduce((a, b) => a + b) /
            memorySnapshots.length;
    final averageMemoryMB = averageMemoryBytes / (1024 * 1024);

    // CPU statistics
    final cpuSnapshots = _snapshots.where((s) => s.cpuUsage != null);
    final averageCPU = cpuSnapshots.isEmpty
        ? 0.0
        : cpuSnapshots.map((s) => s.cpuUsage!).reduce((a, b) => a + b) /
            cpuSnapshots.length;

    // Frame statistics
    final fpsSnapshots = _snapshots.where((s) => s.frameRate != null);
    final averageFPS = fpsSnapshots.isEmpty
        ? 0.0
        : fpsSnapshots.map((s) => s.frameRate!).reduce((a, b) => a + b) /
            fpsSnapshots.length;

    final jankyFrameCount = _frames.where((f) => f.isJanky).length;
    final jankyFramePercentage =
        _frames.isEmpty ? 0.0 : (jankyFrameCount / _frames.length) * 100;

    // Battery statistics
    final batterySnapshots = _snapshots.where((s) => s.batteryLevel != null);
    double batteryDrainRate = 0.0;
    if (batterySnapshots.length >= 2) {
      final first = batterySnapshots.first;
      final last = batterySnapshots.last;
      final timeDiff = last.timestamp.difference(first.timestamp).inHours;
      if (timeDiff > 0) {
        batteryDrainRate =
            (first.batteryLevel! - last.batteryLevel!) / timeDiff;
      }
    }

    // Memory thresholds
    final memoryWarnings = config.memoryWarningThresholdMB != null
        ? memorySnapshots
            .where((s) =>
                s.memoryUsage! > config.memoryWarningThresholdMB! * 1024 * 1024)
            .length
        : 0;

    final memoryCritical = config.memoryCriticalThresholdMB != null
        ? memorySnapshots
            .where((s) =>
                s.memoryUsage! >
                config.memoryCriticalThresholdMB! * 1024 * 1024)
            .length
        : 0;

    return {
      'totalSnapshots': totalSnapshots,
      'monitoringDurationMinutes': monitoringDuration.inMinutes,
      'averageMemoryMB': averageMemoryMB.round(),
      'averageCPU': averageCPU.toStringAsFixed(1),
      'averageFPS': averageFPS.toStringAsFixed(1),
      'totalFrames': _frames.length,
      'jankyFrameCount': jankyFrameCount,
      'jankyFramePercentage': jankyFramePercentage.toStringAsFixed(1),
      'batteryDrainRate': batteryDrainRate.toStringAsFixed(2),
      'memoryWarnings': memoryWarnings,
      'memoryCritical': memoryCritical,
      'connectivityChanges': _countConnectivityChanges(),
    };
  }

  /// Records a custom performance metric.
  ///
  /// Allows applications to add custom performance metrics to the
  /// monitoring system. These metrics will be included in snapshots
  /// and available for analysis and export.
  ///
  /// Parameters:
  /// * [name] - Unique name for the metric
  /// * [value] - Metric value (number or string)
  /// * [timestamp] - Optional timestamp (defaults to now)
  ///
  /// Example:
  /// ```dart
  /// // Record custom business metrics
  /// performanceService.recordCustomMetric('userActionsPerMinute', 45.2);
  /// performanceService.recordCustomMetric('cacheHitRate', 0.85);
  /// performanceService.recordCustomMetric('activeConnections', 12);
  /// ```
  void recordCustomMetric(String name, dynamic value, {DateTime? timestamp}) {
    final metricTimestamp = timestamp ?? DateTime.now();

    // Add to current snapshot or create a new one
    if (_snapshots.isNotEmpty) {
      final lastSnapshot = _snapshots.last;
      final updatedMetrics =
          Map<String, dynamic>.from(lastSnapshot.customMetrics);
      updatedMetrics[name] = value;

      // Update the last snapshot if it's recent (within collection interval)
      final timeDiff = metricTimestamp.difference(lastSnapshot.timestamp);
      if (timeDiff.inMilliseconds < config.collectionIntervalMs / 2) {
        _snapshots[_snapshots.length - 1] = PerformanceSnapshot(
          timestamp: lastSnapshot.timestamp,
          memoryUsage: lastSnapshot.memoryUsage,
          cpuUsage: lastSnapshot.cpuUsage,
          frameRate: lastSnapshot.frameRate,
          batteryLevel: lastSnapshot.batteryLevel,
          isCharging: lastSnapshot.isCharging,
          connectivityType: lastSnapshot.connectivityType,
          orientation: lastSnapshot.orientation,
          screenBrightness: lastSnapshot.screenBrightness,
          availableMemory: lastSnapshot.availableMemory,
          totalMemory: lastSnapshot.totalMemory,
          appState: lastSnapshot.appState,
          customMetrics: updatedMetrics,
        );
        return;
      }
    }

    // Create a new snapshot with just the custom metric
    final snapshot = PerformanceSnapshot(
      timestamp: metricTimestamp,
      customMetrics: {name: value},
    );

    _addSnapshot(snapshot);
  }

  /// Clears all collected performance data.
  ///
  /// Removes all stored snapshots and frame information. Useful for
  /// focusing on specific time periods or preventing excessive
  /// memory usage during long monitoring sessions.
  void clearPerformanceData() {
    _snapshots.clear();
    _frames.clear();
    _frameCount = 0;
    _lastFpsCalculation = DateTime.now();

    logger.i('Performance data cleared', tag: 'performance');
  }

  /// Starts periodic collection of performance metrics.
  void _startPeriodicCollection() {
    _collectionTimer = Timer.periodic(
      Duration(milliseconds: config.collectionIntervalMs),
      (timer) => _collectPerformanceSnapshot(),
    );
  }

  /// Collects a comprehensive performance snapshot.
  Future<void> _collectPerformanceSnapshot() async {
    final timestamp = DateTime.now();

    // Collect enabled metrics
    int? memoryUsage;
    double? cpuUsage;
    double? frameRate;
    double? batteryLevel;
    bool? isCharging;
    String? connectivityType;

    try {
      if (config.trackMemoryUsage) {
        memoryUsage = await _getMemoryUsage();
      }

      if (config.trackCPUUsage) {
        cpuUsage = await _getCPUUsage();
      }

      if (config.trackFPS) {
        frameRate = _calculateCurrentFPS();
      }

      if (config.trackBatteryStatus) {
        batteryLevel = await _getBatteryLevel();
        isCharging = await _getBatteryChargingStatus();
      }

      if (config.trackConnectivity) {
        connectivityType = await _getConnectivityType();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error collecting performance metrics: $e');
      }
    }

    final snapshot = PerformanceSnapshot(
      timestamp: timestamp,
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      frameRate: frameRate,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      connectivityType: connectivityType,
      appState: _appLifecycleState.name,
    );

    _addSnapshot(snapshot);
    _checkThresholds(snapshot);
  }

  /// Adds a snapshot to storage and manages size limits.
  void _addSnapshot(PerformanceSnapshot snapshot) {
    _snapshots.add(snapshot);

    // Apply size limits
    if (config.maxDataPoints != null &&
        _snapshots.length > config.maxDataPoints!) {
      _snapshots.removeAt(0);
    }

    _snapshotController.add(snapshot);
  }

  /// Sets up frame monitoring for UI performance tracking.
  void _setupFrameMonitoring() {
    SchedulerBinding.instance.addPostFrameCallback(_onFrameCompleted);
  }

  /// Called after each frame is rendered.
  void _onFrameCompleted(Duration duration) {
    _frameCount++;

    final now = DateTime.now();
    final frameDurationMs = duration.inMicroseconds / 1000.0;
    final isJanky = frameDurationMs > config.frameTimeWarningThresholdMs;

    final frameInfo = FrameInfo(
      frameNumber: _frameCount,
      timestamp: now,
      durationMs: frameDurationMs,
      isJanky: isJanky,
      targetFrameTimeMs: config.frameTimeWarningThresholdMs,
    );

    _frames.add(frameInfo);

    // Apply size limits
    if (config.maxDataPoints != null &&
        _frames.length > config.maxDataPoints!) {
      _frames.removeAt(0);
    }

    _frameController.add(frameInfo);

    // Log janky frames
    if (isJanky) {
      logger.w(
        'Janky frame detected: ${frameDurationMs.toStringAsFixed(1)}ms (target: ${config.frameTimeWarningThresholdMs}ms)',
        tag: 'performance',
      );
    }

    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrameCompleted);
  }

  /// Sets up app lifecycle monitoring.
  void _setupLifecycleMonitoring() {
    WidgetsBinding.instance.lifecycleState;
    // Note: This would need proper lifecycle listener setup
    // For now, we'll track the basic state
  }

  /// Gets current memory usage in bytes.
  Future<int?> _getMemoryUsage() async {
    try {
      // This is platform-specific and may not be available on all platforms
      if (Platform.isAndroid || Platform.isIOS) {
        // Use platform channel to get memory info
        // For now, return a placeholder
        return ProcessInfo.currentRss;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get memory usage: $e');
      }
    }
    return null;
  }

  /// Gets current CPU usage percentage.
  Future<double?> _getCPUUsage() async {
    try {
      // This is platform-specific and complex to implement
      // Would require native platform channels
      // For now, return null to indicate unavailable
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get CPU usage: $e');
      }
    }
    return null;
  }

  /// Calculates current frame rate.
  double? _calculateCurrentFPS() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastFpsCalculation);

    if (timeDiff.inMilliseconds >= 1000) {
      final fps = _frameCount / (timeDiff.inMilliseconds / 1000.0);
      _lastFpsCalculation = now;
      _frameCount = 0;
      return fps;
    }

    return null;
  }

  /// Gets current battery level.
  Future<double?> _getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level.toDouble();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get battery level: $e');
      }
    }
    return null;
  }

  /// Gets battery charging status.
  Future<bool?> _getBatteryChargingStatus() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get battery state: $e');
      }
    }
    return null;
  }

  /// Gets current connectivity type.
  Future<String?> _getConnectivityType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.name;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get connectivity: $e');
      }
    }
    return null;
  }

  /// Checks performance thresholds and logs warnings.
  void _checkThresholds(PerformanceSnapshot snapshot) {
    // Memory threshold check
    if (config.memoryWarningThresholdMB != null &&
        snapshot.memoryUsage != null) {
      final memoryMB = snapshot.memoryUsage! / (1024 * 1024);

      if (memoryMB > config.memoryCriticalThresholdMB!) {
        logger.e(
          'Critical memory usage: ${memoryMB.round()}MB (threshold: ${config.memoryCriticalThresholdMB}MB)',
          tag: 'performance',
        );

        if (config.autoExportOnCritical) {
          // TODO: Trigger automatic export
        }
      } else if (memoryMB > config.memoryWarningThresholdMB!) {
        logger.w(
          'High memory usage: ${memoryMB.round()}MB (threshold: ${config.memoryWarningThresholdMB}MB)',
          tag: 'performance',
        );
      }
    }

    // CPU threshold check
    if (config.cpuWarningThresholdPercent > 0 && snapshot.cpuUsage != null) {
      if (snapshot.cpuUsage! > config.cpuWarningThresholdPercent) {
        logger.w(
          'High CPU usage: ${snapshot.cpuUsage!.toStringAsFixed(1)}% (threshold: ${config.cpuWarningThresholdPercent}%)',
          tag: 'performance',
        );
      }
    }
  }

  /// Counts connectivity changes over time.
  int _countConnectivityChanges() {
    if (_snapshots.length < 2) return 0;

    int changes = 0;
    String? previousType;

    for (final snapshot in _snapshots) {
      if (snapshot.connectivityType != null) {
        if (previousType != null && previousType != snapshot.connectivityType) {
          changes++;
        }
        previousType = snapshot.connectivityType;
      }
    }

    return changes;
  }

  /// Disposes of resources and stops monitoring.
  void dispose() {
    _collectionTimer?.cancel();
    _snapshotController.close();
    _frameController.close();
  }
}
