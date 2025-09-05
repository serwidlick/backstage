/// Performance monitoring and metrics collection configuration.
///
/// This file defines configuration options for system performance tracking,
/// including CPU usage, memory consumption, frame rates, battery status,
/// and other device metrics that can help identify performance issues.
library;

/// Configuration options for performance monitoring and metrics collection.
///
/// [PerformanceConfig] specifies which performance metrics should be tracked,
/// how frequently they should be collected, and what thresholds should trigger
/// warnings or alerts in the debugging console.
///
/// **Performance Impact**:
/// * Metric collection itself consumes resources (CPU, memory, battery)
/// * Higher collection frequencies increase overhead
/// * Some metrics (like detailed memory analysis) are more expensive
/// * Balance monitoring needs with performance impact
///
/// **Platform Availability**:
/// * Not all metrics are available on all platforms
/// * Mobile platforms typically provide more detailed metrics
/// * Web platform has limited system access
///
/// Example configurations:
/// ```dart
/// // Development configuration (comprehensive monitoring)
/// const devConfig = PerformanceConfig(
///   trackMemoryUsage: true,
///   trackCPUUsage: true,
///   trackFPS: true,
///   trackBatteryStatus: true,
///   collectionIntervalMs: 1000, // Every second
/// );
///
/// // Production configuration (minimal monitoring)
/// const prodConfig = PerformanceConfig(
///   trackMemoryUsage: true,
///   trackFPS: false, // Skip expensive FPS monitoring
///   collectionIntervalMs: 5000, // Every 5 seconds
///   memoryWarningThresholdMB: 200, // Alert on high memory usage
/// );
/// ```
class PerformanceConfig {
  /// Whether to track application memory usage.
  ///
  /// When enabled, memory consumption metrics including heap usage,
  /// garbage collection events, and memory warnings will be tracked
  /// and displayed in the performance tab.
  ///
  /// **Default**: `true`
  /// **Performance**: Low overhead, highly valuable for debugging
  /// **Platforms**: Available on all platforms
  final bool trackMemoryUsage;

  /// Whether to track CPU usage statistics.
  ///
  /// When enabled, CPU utilization metrics for the application
  /// and system will be collected and displayed. This can help
  /// identify performance bottlenecks and inefficient code paths.
  ///
  /// **Default**: `false`
  /// **Performance**: Moderate overhead, platform-dependent accuracy
  /// **Platforms**: Limited availability on some platforms
  final bool trackCPUUsage;

  /// Whether to track frame rate and rendering performance.
  ///
  /// When enabled, frame rendering times, dropped frames, and
  /// overall FPS metrics will be tracked to identify UI performance
  /// issues and janky animations.
  ///
  /// **Default**: `true`
  /// **Performance**: Moderate overhead, very useful for UI debugging
  /// **Platforms**: Available on all platforms with rendering
  final bool trackFPS;

  /// Whether to track device battery status and usage.
  ///
  /// When enabled, battery level, charging status, and power
  /// consumption estimates will be tracked to identify
  /// battery-draining operations.
  ///
  /// **Default**: `false`
  /// **Performance**: Low overhead, useful for mobile apps
  /// **Platforms**: Mobile platforms only
  final bool trackBatteryStatus;

  /// Whether to track network connectivity status.
  ///
  /// When enabled, network connection type, signal strength,
  /// and connectivity changes will be monitored to correlate
  /// performance issues with network conditions.
  ///
  /// **Default**: `true`
  /// **Performance**: Very low overhead, useful for debugging
  /// **Platforms**: Available on all platforms
  final bool trackConnectivity;

  /// Whether to track application startup performance.
  ///
  /// When enabled, detailed startup timing including initialization
  /// phases, first frame render, and route loading will be measured
  /// to optimize application launch performance.
  ///
  /// **Default**: `true`
  /// **Performance**: One-time cost during startup
  /// **Utility**: Critical for user experience optimization
  final bool trackStartupPerformance;

  /// Interval in milliseconds between performance metric collections.
  ///
  /// Lower values provide more granular data but increase overhead.
  /// Higher values reduce impact but may miss short-term performance
  /// issues. Balance based on your monitoring needs.
  ///
  /// **Default**: `2000` (2 seconds)
  /// **Performance**: Lower values = higher overhead
  /// **Range**: Recommended 1000-10000ms
  final int collectionIntervalMs;

  /// Memory usage threshold in MB that triggers warnings.
  ///
  /// When memory usage exceeds this threshold, warning-level log
  /// entries will be generated to alert developers of potential
  /// memory issues. Set to null to disable memory warnings.
  ///
  /// **Default**: `null` (no threshold)
  /// **Utility**: Helps identify memory leaks early
  final int? memoryWarningThresholdMB;

  /// Memory usage threshold in MB that triggers critical alerts.
  ///
  /// When memory usage exceeds this threshold, error-level log
  /// entries will be generated to alert developers of critical
  /// memory issues that may cause app crashes or poor performance.
  ///
  /// **Default**: `null` (no threshold)
  /// **Utility**: Prevents out-of-memory crashes
  final int? memoryCriticalThresholdMB;

  /// Frame time threshold in milliseconds that triggers performance warnings.
  ///
  /// When frame rendering takes longer than this threshold, warnings
  /// will be logged to identify janky animations and slow UI updates.
  /// 16.67ms equals 60 FPS, 33.33ms equals 30 FPS.
  ///
  /// **Default**: `16.67` (60 FPS threshold)
  /// **Utility**: Identifies UI performance issues
  final double frameTimeWarningThresholdMs;

  /// CPU usage percentage that triggers performance warnings.
  ///
  /// When CPU usage exceeds this percentage, warnings will be
  /// logged to identify CPU-intensive operations that may cause
  /// performance degradation.
  ///
  /// **Default**: `80.0` (80% CPU usage)
  /// **Range**: 0.0-100.0
  final double cpuWarningThresholdPercent;


  /// Maximum number of performance data points to retain in memory.
  ///
  /// Older data points will be automatically removed to prevent
  /// unlimited memory growth. Set to null for no limit (not
  /// recommended for long-running applications).
  ///
  /// **Default**: `1000`
  /// **Performance**: Prevents memory leaks from performance data
  final int? maxDataPoints;

  /// Whether to automatically export performance reports on critical issues.
  ///
  /// When enabled, detailed performance reports will be automatically
  /// generated and exported when critical thresholds are exceeded,
  /// providing immediate debugging information for severe issues.
  ///
  /// **Default**: `false`
  /// **Utility**: Provides immediate debugging data for critical issues
  final bool autoExportOnCritical;

  /// Creates a new performance configuration with the specified options.
  ///
  /// All parameters are optional and have balanced defaults that provide
  /// useful performance monitoring without excessive overhead. Adjust
  /// based on your specific performance monitoring needs.
  ///
  /// Example:
  /// ```dart
  /// const config = PerformanceConfig(
  ///   trackMemoryUsage: true,
  ///   trackFPS: true,
  ///   collectionIntervalMs: 1000,
  ///   memoryWarningThresholdMB: 100,
  ///   memoryCriticalThresholdMB: 200,
  ///   frameTimeWarningThresholdMs: 16.67, // 60 FPS
  /// );
  /// ```
  const PerformanceConfig({
    this.trackMemoryUsage = true,
    this.trackCPUUsage = false,
    this.trackFPS = true,
    this.trackBatteryStatus = false,
    this.trackConnectivity = true,
    this.trackStartupPerformance = true,
    this.collectionIntervalMs = 2000,
    this.memoryWarningThresholdMB,
    this.memoryCriticalThresholdMB,
    this.frameTimeWarningThresholdMs = 16.67, // 60 FPS
    this.cpuWarningThresholdPercent = 80.0,
    this.maxDataPoints = 1000,
    this.autoExportOnCritical = false,
  });
}
