/// Core Backstage initialization and configuration management.
///
/// This file contains the main Backstage class and configuration system
/// that coordinates all debugging console functionality. It manages the
/// overall lifecycle, persistence, error capture setup, and global state.
///
/// Key components:
/// * [Backstage] - Main singleton class managing console state
/// * [BackstageConfig] - Configuration options for initialization
/// * Global error zone management for comprehensive error capture
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'capture.dart';
import 'config/backstage_config.dart';
import 'logger.dart';
import 'storage.dart';

// The comprehensive BackstageConfig is now in config/backstage_config.dart
// This keeps the old simple config for backward compatibility
class LegacyBackstageConfig {
  final bool capturePrint;
  final bool captureFlutterErrors;
  final bool captureZoneErrors;
  final String? passcode;
  final bool enabledByDefault;
  final bool persistEnabled;

  const LegacyBackstageConfig({
    this.capturePrint = true,
    this.captureFlutterErrors = true,
    this.captureZoneErrors = false,
    this.passcode,
    this.enabledByDefault = false,
    this.persistEnabled = true,
  });

  /// Convert to comprehensive BackstageConfig
  BackstageConfig toBackstageConfig() {
    return BackstageConfig(
      capturePrint: capturePrint,
      captureFlutterErrors: captureFlutterErrors,
      captureZoneErrors: captureZoneErrors,
      passcode: passcode,
      enabledByDefault: enabledByDefault,
      persistEnabled: persistEnabled,
    );
  }
}

/// Main singleton class that manages the Backstage debugging console.
///
/// [Backstage] coordinates all debugging console functionality including
/// initialization, configuration management, error capture setup, state
/// persistence, and lifecycle management. It uses a singleton pattern
/// to ensure consistent global state throughout the application.
///
/// **Lifecycle Overview**:
/// 1. Call [Backstage().init] early in app initialization
/// 2. Optionally wrap main app with [runZoned] for async error capture
/// 3. Console state is managed automatically based on user interactions
/// 4. State persists across app restarts if configured
///
/// **Thread Safety**: The main Backstage instance is thread-safe for
/// read operations. State changes ([setEnabled]) should be called from
/// the main isolate to ensure proper UI synchronization.
///
/// **Memory Management**: The singleton instance and its logger remain
/// in memory for the application's lifetime. This is intentional to
/// maintain error capture capabilities and state consistency.
///
/// Example usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await Backstage().init(BackstageConfig(
///     capturePrint: true,
///     captureFlutterErrors: true,
///     passcode: kReleaseMode ? 'debug123' : null,
///   ));
///
///   // For zone error capture (optional)
///   Backstage.I.runZoned(() => runApp(MyApp()));
/// }
/// ```
///
/// **Access Patterns**:
/// * `Backstage()` - Standard constructor (returns singleton)
/// * `Backstage.I` - Static property for quick access
/// * Both patterns return the same singleton instance
class Backstage {
  /// The singleton instance used throughout the application.
  ///
  /// This instance is created lazily on first access and persists
  /// for the application's lifetime to maintain consistent state
  /// and error capture capabilities.
  static final Backstage _i = Backstage._();

  /// Private constructor to enforce singleton pattern.
  Backstage._();

  /// Factory constructor that returns the singleton instance.
  ///
  /// This is the standard way to access the Backstage instance.
  /// Multiple calls return the same singleton instance.
  factory Backstage() => _i;

  /// Persistent storage manager for configuration and state.
  ///
  /// Handles saving and loading the console's enabled state
  /// across application restarts using platform-appropriate
  /// storage mechanisms.
  final _store = BackstageStore();

  /// The logger instance that collects and manages all log entries.
  ///
  /// This logger receives input from error capture hooks, manual
  /// logging calls, and other debugging output sources. Its stream
  /// is consumed by the console UI to display entries.
  ///
  /// **Public Access**: This is intentionally public to allow
  /// direct logging from application code.
  final logger = BackstageLogger();

  /// Current configuration applied during initialization.
  ///
  /// Stores the configuration passed to [init] and used throughout
  /// the application lifecycle to determine capture behavior and
  /// security settings.
  BackstageConfig _cfg = const BackstageConfig();

  /// Reactive state indicating whether the console is currently enabled.
  ///
  /// This [ValueNotifier] allows the UI to react to console state
  /// changes and provides a clean way to observe enablement status.
  /// Changes to this notifier are automatically persisted if
  /// [BackstageConfig.persistEnabled] is `true`.
  ///
  /// **UI Integration**: The overlay UI listens to this notifier
  /// to show/hide the console interface.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// Initializes the Backstage debugging console with the provided configuration.
  ///
  /// This method supports both the comprehensive [BackstageConfig] and the
  /// legacy simple configuration for backward compatibility. It must be called
  /// early in the application lifecycle, typically in main() after
  /// [WidgetsFlutterBinding.ensureInitialized()].
  ///
  /// **Setup Order**:
  /// 1. Converts legacy config if needed
  /// 2. Stores the configuration
  /// 3. Restores enabled state from persistent storage (if configured)
  /// 4. Sets up print output capture (if configured)
  /// 5. Sets up Flutter framework error capture (if configured)
  /// 6. Initializes additional features based on configuration
  ///
  /// Parameters:
  /// * [config] - Configuration options defining console behavior
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   await Backstage().init(BackstageConfig(
  ///     // Core logging
  ///     capturePrint: true,
  ///     captureFlutterErrors: true,
  ///
  ///     // Network monitoring
  ///     captureNetworkRequests: true,
  ///
  ///     // Performance tracking
  ///     capturePerformanceMetrics: true,
  ///
  ///     // Security
  ///     passcode: kReleaseMode ? 'secure123' : null,
  ///     requireBiometric: kReleaseMode,
  ///
  ///     // Export capabilities
  ///     enableExport: true,
  ///   ));
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// **Backward Compatibility**: The legacy LegacyBackstageConfig is still
  /// supported and will be automatically converted to the comprehensive config.
  ///
  /// Throws:
  /// * [StateError] if persistent storage cannot be accessed
  /// * [PlatformException] if platform-specific initialization fails
  Future<void> init(dynamic config) async {
    // Handle both new and legacy config types
    if (config is LegacyBackstageConfig) {
      _cfg = config.toBackstageConfig();
    } else if (config is BackstageConfig) {
      _cfg = config;
    } else {
      throw ArgumentError(
          'Configuration must be BackstageConfig or LegacyBackstageConfig');
    }

    // Restore persistent state
    if (_cfg.persistEnabled) {
      final persisted = await _store.readEnabled();
      enabled.value = persisted ?? _cfg.enabledByDefault;
    } else {
      enabled.value = _cfg.enabledByDefault;
    }

    // Set up core logging hooks
    if (_cfg.capturePrint) Capture.hookPrint(logger);
    if (_cfg.captureFlutterErrors) Capture.hookFlutterErrors(logger);

    // TODO: Initialize additional features based on configuration
    // These will be implemented in subsequent steps:
    // - Network request logging
    // - Performance monitoring
    // - Remote logging
    // - Security features
    // - Storage persistence
    // - Platform-specific features
  }

  /// Wraps application execution in a guarded zone for comprehensive error capture.
  ///
  /// This method should be used to wrap your main application entry point when
  /// [BackstageConfig.captureZoneErrors] is set to `true`. It creates a zone
  /// that catches uncaught async errors and forwards them to the Backstage logger.
  ///
  /// **When to Use**: Enable zone error capture when you need visibility into
  /// async errors that would otherwise be silently lost, such as:
  /// * Uncaught Future errors
  /// * Timer callback errors
  /// * Stream subscription errors
  /// * Isolate communication errors
  ///
  /// **Performance Impact**: Adds minimal overhead to async operations.
  /// The zone wrapper is efficient and only activates when errors occur.
  ///
  /// Parameters:
  /// * [body] - The function containing your application entry point
  ///
  /// Returns: The result of executing [body], preserving the original return type
  ///
  /// **Usage Pattern**:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   await Backstage().init(BackstageConfig(
  ///     captureZoneErrors: true, // Enable zone error capture
  ///   ));
  ///
  ///   // Wrap your app entry point
  ///   Backstage.I.runZoned(() => runApp(MyApp()));
  /// }
  /// ```
  ///
  /// **Error Information Captured**:
  /// * Complete error message via [toString()]
  /// * Full stack trace for debugging context
  /// * Tagged with 'zone' for easy filtering
  /// * Logged at error level
  ///
  /// **Behavior**: If [BackstageConfig.captureZoneErrors] is `false`,
  /// this method simply executes [body] directly without zone wrapping,
  /// allowing you to safely call it regardless of configuration.
  T runZoned<T>(T Function() body) {
    if (!_cfg.captureZoneErrors) return body();
    late T result;
    runZonedGuarded(() {
      result = body();
    }, (e, st) {
      logger.add(BackstageLog(
        message: e.toString(),
        level: BackstageLevel.error,
        tag: 'zone',
        stackTrace: st,
      ));
    });
    return result;
  }

  /// Updates the console's enabled state and optionally persists the change.
  ///
  /// This method changes the console's visibility state and, if persistence
  /// is enabled in the configuration, saves the new state to platform storage
  /// so it will be restored on the next app launch.
  ///
  /// **State Synchronization**: The change is immediately reflected in the
  /// [enabled] ValueNotifier, causing any listening UI components to update
  /// their visibility state.
  ///
  /// Parameters:
  /// * [value] - `true` to enable and show the console, `false` to disable and hide it
  ///
  /// **Persistence Behavior**:
  /// * If [BackstageConfig.persistEnabled] is `true`: State is saved to storage
  /// * If [BackstageConfig.persistEnabled] is `false`: State is only kept in memory
  ///
  /// **UI Integration**: This method is typically called by:
  /// * The activation gesture handler in [BackstageEntryGate]
  /// * The close button in the console UI
  /// * Custom application code for programmatic control
  ///
  /// Example:
  /// ```dart
  /// // Enable the console programmatically
  /// await Backstage.I.setEnabled(true);
  ///
  /// // Disable the console
  /// await Backstage.I.setEnabled(false);
  /// ```
  ///
  /// **Thread Safety**: Should be called from the main isolate to ensure
  /// proper UI synchronization and storage operation safety.
  ///
  /// Throws:
  /// * [PlatformException] if persistent storage write fails
  /// * [StateError] if storage system is not properly initialized
  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    if (_cfg.persistEnabled) {
      await _store.writeEnabled(value);
    }
  }

  /// Gets the current enabled state of the console.
  ///
  /// This getter provides synchronous access to the console's current
  /// visibility state. It reflects the current value of the [enabled]
  /// ValueNotifier without requiring stream subscription.
  ///
  /// Returns:
  /// * `true` if the console is currently enabled and visible
  /// * `false` if the console is currently disabled and hidden
  ///
  /// **Usage**: This is useful for conditional logic or state checks:
  /// ```dart
  /// if (Backstage.I.isEnabled) {
  ///   // Console is active, maybe log additional debug info
  ///   Backstage.I.logger.d('Console is active');
  /// }
  /// ```
  ///
  /// **Alternative**: For reactive UI updates, subscribe to the [enabled]
  /// ValueNotifier instead of polling this getter.
  bool get isEnabled => enabled.value;

  /// Static convenience property for quick access to the singleton instance.
  ///
  /// This provides a shorter syntax for accessing the Backstage singleton
  /// when you need to make multiple calls or when brevity is preferred.
  ///
  /// **Equivalent Access Patterns**:
  /// ```dart
  /// // These are identical:
  /// Backstage.I.logger.i('Message');
  /// Backstage().logger.i('Message');
  ///
  /// // The static property is more concise for multiple operations:
  /// final backstage = Backstage.I;
  /// backstage.logger.i('Info message');
  /// await backstage.setEnabled(false);
  /// ```
  static Backstage get I => _i;
}
