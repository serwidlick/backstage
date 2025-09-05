/// Comprehensive configuration system for the Backstage debugging console.
///
/// This file contains the enhanced configuration options that support all
/// advanced features including network logging, performance monitoring,
/// export capabilities, security features, and UI customization.
library;

import 'package:flutter/material.dart';

import 'export_config.dart';
import 'network_config.dart';
import 'performance_config.dart';
import 'security_config.dart';
import 'storage_config.dart';
import 'theme_config.dart';
import 'ui_config.dart';

/// Enumeration of supported export formats for log data.
enum ExportFormat { json, csv, text, html }

/// Enumeration of supported crash reporting providers.
enum CrashProvider { none, crashlytics, sentry, bugsnag }

/// Enumeration of available console themes.
enum BackstageTheme { system, light, dark, custom }

/// Comprehensive configuration options for initializing the Backstage debugging console.
///
/// [BackstageConfig] defines how the Backstage system should behave across all
/// features including logging, networking, performance monitoring, security,
/// export capabilities, and UI customization. This configuration is applied
/// during [Backstage.init] and affects the console's behavior throughout
/// the application lifecycle.
///
/// **Feature Categories**:
/// * **Core Logging**: Basic log capture and display
/// * **Network Monitoring**: HTTP request/response logging
/// * **Performance Tracking**: System metrics and performance data
/// * **Security**: Authentication, sanitization, and access control
/// * **Export & Sharing**: Data export and sharing capabilities
/// * **UI Customization**: Theming, layouts, and user experience
/// * **Platform Integration**: Platform-specific features and integrations
///
/// Example configurations:
/// ```dart
/// // Minimal configuration for development
/// const devConfig = BackstageConfig(
///   enabledByDefault: true,
///   capturePrint: true,
///   captureFlutterErrors: true,
/// );
///
/// // Full-featured production configuration
/// const prodConfig = BackstageConfig(
///   // Core settings
///   passcode: 'secure123',
///   enabledByDefault: false,
///
///   // Network monitoring
///   captureNetworkRequests: true,
///   networkConfig: NetworkConfig(
///     captureHeaders: false, // Security: don't log headers in prod
///     captureBody: false,
///   ),
///
///   // Performance monitoring
///   capturePerformanceMetrics: true,
///   performanceConfig: PerformanceConfig(
///     trackMemoryUsage: true,
///     trackFPS: true,
///   ),
///
///   // Security
///   requireBiometric: true,
///   securityConfig: SecurityConfig(
///     sanitizePatterns: ['password=.*', 'token=.*'],
///   ),
///
///   // Export capabilities
///   enableExport: true,
///   exportConfig: ExportConfig(
///     allowedFormats: [ExportFormat.json, ExportFormat.csv],
///   ),
/// );
/// ```
class BackstageConfig {
  // ============================================================================
  // CORE LOGGING CONFIGURATION
  // ============================================================================

  /// Whether to intercept print() and debugPrint() output.
  ///
  /// When enabled, all print and debugPrint calls will be captured
  /// and displayed in the Backstage console in addition to the
  /// system console. This is useful for seeing debug output in
  /// production builds where system console access is limited.
  ///
  /// **Default**: `true`
  /// **Performance**: Minimal overhead, output is processed synchronously
  final bool capturePrint;

  /// Whether to capture Flutter framework errors.
  ///
  /// When enabled, Flutter framework errors (widget build errors,
  /// render errors, etc.) will be captured and displayed in the
  /// Backstage console. These errors are normally only visible
  /// during development.
  ///
  /// **Default**: `true`
  /// **Performance**: No overhead when no errors occur
  final bool captureFlutterErrors;

  /// Whether to wrap the application in a zone for capturing async errors.
  ///
  /// When enabled, uncaught async errors will be captured and displayed
  /// in the Backstage console. This requires wrapping your main app
  /// entry point with [Backstage.runZoned].
  ///
  /// **Default**: `false` (due to setup complexity)
  /// **Performance**: Slight overhead for all async operations
  /// **Usage**: Requires calling `Backstage.runZoned(() => runApp(...))`
  final bool captureZoneErrors;

  /// Optional passcode required to activate the console.
  ///
  /// When set, users must enter this passcode after performing the
  /// activation gesture to enable the console. This provides security
  /// in production environments by preventing unauthorized access to
  /// potentially sensitive debug information.
  ///
  /// **Default**: `null` (no passcode required)
  /// **Security**: Use a non-obvious passcode in production builds
  final String? passcode;

  /// Whether the console should be enabled by default on first run.
  ///
  /// When `true`, the console will be active immediately after
  /// initialization. When `false`, users must perform the activation
  /// gesture to enable it. This setting only affects first run -
  /// subsequent runs restore the last user-selected state if
  /// [persistEnabled] is `true`.
  ///
  /// **Default**: `false`
  /// **Recommendation**: Set to `false` in production builds
  final bool enabledByDefault;

  /// Whether to persist the enabled/disabled state across app restarts.
  ///
  /// When `true`, the console's enabled state is saved when changed
  /// and restored on the next app launch. When `false`, the console
  /// always starts in the [enabledByDefault] state.
  ///
  /// **Default**: `true`
  /// **Storage**: Uses platform-appropriate persistent storage
  final bool persistEnabled;

  // ============================================================================
  // NETWORK MONITORING CONFIGURATION
  // ============================================================================

  /// Whether to automatically capture HTTP requests and responses.
  ///
  /// When enabled, HTTP requests made through common HTTP clients
  /// (Dio, http package) will be automatically intercepted and logged
  /// to the console with request/response details.
  ///
  /// **Default**: `false`
  /// **Security**: May capture sensitive data - configure [networkConfig] carefully
  final bool captureNetworkRequests;

  /// Detailed configuration for network request logging.
  ///
  /// Specifies what aspects of HTTP requests and responses should be
  /// captured, including headers, body content, timing information,
  /// and error details.
  ///
  /// **Default**: `NetworkConfig()` (conservative defaults)
  final NetworkConfig networkConfig;

  // ============================================================================
  // PERFORMANCE MONITORING CONFIGURATION
  // ============================================================================

  /// Whether to track and display performance metrics.
  ///
  /// When enabled, system performance metrics like memory usage,
  /// CPU utilization, frame rates, and battery status will be
  /// monitored and available in the console.
  ///
  /// **Default**: `false`
  /// **Performance**: Adds minimal overhead for metric collection
  final bool capturePerformanceMetrics;

  /// Detailed configuration for performance monitoring.
  ///
  /// Specifies which performance metrics to track, collection
  /// intervals, and thresholds for performance warnings.
  ///
  /// **Default**: `PerformanceConfig()` (basic metrics only)
  final PerformanceConfig performanceConfig;

  // ============================================================================
  // SECURITY AND PRIVACY CONFIGURATION
  // ============================================================================

  /// Whether to require biometric authentication for console access.
  ///
  /// When enabled, users must provide biometric authentication
  /// (fingerprint, face recognition, etc.) in addition to any
  /// configured passcode to access the console.
  ///
  /// **Default**: `false`
  /// **Platform**: Requires device biometric capabilities
  final bool requireBiometric;

  /// Comprehensive security configuration options.
  ///
  /// Includes data sanitization rules, access controls, and
  /// privacy protection settings to ensure sensitive information
  /// is not exposed through the debugging console.
  ///
  /// **Default**: `SecurityConfig()` (basic sanitization)
  final SecurityConfig securityConfig;

  // ============================================================================
  // EXPORT AND SHARING CONFIGURATION
  // ============================================================================

  /// Whether to enable log export and sharing functionality.
  ///
  /// When enabled, users can export log data in various formats
  /// and share it through platform sharing mechanisms.
  ///
  /// **Default**: `false`
  /// **Security**: Consider data sensitivity before enabling
  final bool enableExport;

  /// Configuration for export and sharing features.
  ///
  /// Specifies available export formats, file naming conventions,
  /// and sharing options for log data.
  ///
  /// **Default**: `ExportConfig()` (JSON export only)
  final ExportConfig exportConfig;

  // ============================================================================
  // STORAGE AND PERSISTENCE CONFIGURATION
  // ============================================================================

  /// Whether to persist log entries across app sessions.
  ///
  /// When enabled, log entries are saved to device storage and
  /// restored when the app restarts, allowing for historical
  /// log analysis and debugging.
  ///
  /// **Default**: `false`
  /// **Storage**: Uses platform-appropriate storage mechanisms
  final bool persistLogs;

  /// Detailed configuration for log storage and retention.
  ///
  /// Specifies storage locations, retention policies, file sizes,
  /// and cleanup behaviors for persisted log data.
  ///
  /// **Default**: `StorageConfig()` (memory-only storage)
  final StorageConfig storageConfig;

  // ============================================================================
  // UI AND THEME CONFIGURATION
  // ============================================================================

  /// The visual theme for the console interface.
  ///
  /// Determines the color scheme, typography, and visual style
  /// of the debugging console. Can follow system theme or use
  /// custom styling.
  ///
  /// **Default**: `BackstageTheme.system`
  final BackstageTheme theme;

  /// Detailed theme customization options.
  ///
  /// Allows fine-grained control over console appearance including
  /// colors, fonts, spacing, and component styling.
  ///
  /// **Default**: `ThemeConfig()` (Material Design defaults)
  final ThemeConfig themeConfig;

  /// Configuration for console UI layout and behavior.
  ///
  /// Controls console positioning, sizing, interaction modes,
  /// and advanced UI features like tabs and search.
  ///
  /// **Default**: `UIConfig()` (standard layout)
  final UIConfig uiConfig;

  // ============================================================================
  // PLATFORM INTEGRATION CONFIGURATION
  // ============================================================================

  /// Whether to enable platform-specific activation methods.
  ///
  /// When enabled, platform-specific gestures like device shake
  /// (mobile) or keyboard shortcuts (desktop/web) can be used
  /// to activate the console.
  ///
  /// **Default**: `false`
  final bool enablePlatformFeatures;

  /// Crash reporting provider integration.
  ///
  /// When configured, critical errors captured by Backstage can
  /// be automatically forwarded to external crash reporting
  /// services for analysis and alerting.
  ///
  /// **Default**: `CrashProvider.none`
  final CrashProvider crashProvider;

  /// API key or configuration for crash reporting provider.
  ///
  /// Required when [crashProvider] is not [CrashProvider.none].
  /// Contains authentication and routing information for the
  /// external crash reporting service.
  final String? crashProviderConfig;

  // ============================================================================
  // REMOTE LOGGING CONFIGURATION
  // ============================================================================

  /// Whether to enable remote log transmission.
  ///
  /// When enabled, logs can be transmitted to a remote server
  /// for centralized analysis, alerting, and monitoring.
  ///
  /// **Default**: `false`
  /// **Security**: Ensure secure transmission and data handling
  final bool enableRemoteLogging;

  /// Remote logging endpoint URL.
  ///
  /// The server endpoint where logs should be transmitted.
  /// Must be HTTPS in production environments.
  final String? remoteEndpoint;

  /// Authentication configuration for remote logging.
  ///
  /// API keys, tokens, or other authentication mechanisms
  /// required by the remote logging service.
  final Map<String, String>? remoteAuthConfig;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// Creates a new Backstage configuration with the specified options.
  ///
  /// All parameters are optional and have sensible defaults for most
  /// use cases. The default configuration is suitable for development
  /// environments but should be customized for production deployments.
  ///
  /// Example:
  /// ```dart
  /// const config = BackstageConfig(
  ///   capturePrint: true,
  ///   captureFlutterErrors: true,
  ///   passcode: kReleaseMode ? 'prod123' : null,
  ///   enabledByDefault: !kReleaseMode,
  ///   captureNetworkRequests: true,
  ///   capturePerformanceMetrics: true,
  /// );
  ///
  /// await Backstage().init(config);
  /// ```
  const BackstageConfig({
    // Core logging
    this.capturePrint = true,
    this.captureFlutterErrors = true,
    this.captureZoneErrors = false,
    this.passcode,
    this.enabledByDefault = false,
    this.persistEnabled = true,

    // Network monitoring
    this.captureNetworkRequests = false,
    this.networkConfig = const NetworkConfig(),

    // Performance monitoring
    this.capturePerformanceMetrics = false,
    this.performanceConfig = const PerformanceConfig(),

    // Security
    this.requireBiometric = false,
    this.securityConfig = const SecurityConfig(),

    // Export and sharing
    this.enableExport = false,
    this.exportConfig = const ExportConfig(),

    // Storage and persistence
    this.persistLogs = false,
    this.storageConfig = const StorageConfig(),

    // UI and theming
    this.theme = BackstageTheme.system,
    this.themeConfig = const ThemeConfig(),
    this.uiConfig = const UIConfig(),

    // Platform integration
    this.enablePlatformFeatures = false,
    this.crashProvider = CrashProvider.none,
    this.crashProviderConfig,

    // Remote logging
    this.enableRemoteLogging = false,
    this.remoteEndpoint,
    this.remoteAuthConfig,
  });
}
