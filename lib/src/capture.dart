/// Error and output capture functionality for the Backstage debugging console.
///
/// This file provides mechanisms to intercept and capture various types of
/// application output and errors that would normally only be visible in
/// development environments, making them available in the Backstage console
/// for production debugging.
///
/// Supported capture types:
/// * [Capture.hookPrint] - Intercepts print() and debugPrint() output
/// * [Capture.hookFlutterErrors] - Captures Flutter framework errors
/// * Zone error capture (configured separately via BackstageConfig)
library;

import 'package:flutter/foundation.dart';

import 'logger.dart';

/// Provides static methods for intercepting and capturing application output.
///
/// The [Capture] class contains utility methods that hook into various Flutter
/// and Dart output mechanisms to redirect their content to the Backstage logger.
/// This allows developers and support teams to see debug output, print statements,
/// and framework errors directly in the production app console.
///
/// **Important Notes**:
/// * All capture methods modify global Flutter/Dart behavior
/// * Original functionality is preserved (output still goes to system console)
/// * Captures should be set up early in app initialization  
/// * Thread-safe and can be called from any isolate
///
/// **Security Consideration**: Be mindful that captured output may contain
/// sensitive information. Ensure appropriate filtering or sanitization if
/// sharing captured logs.
///
/// Example initialization:
/// ```dart
/// final logger = BackstageLogger();
/// 
/// // Set up all capture mechanisms
/// Capture.hookPrint(logger);
/// Capture.hookFlutterErrors(logger);
/// 
/// // Now all print() and framework errors will appear in Backstage
/// print('This will appear in both console and Backstage');
/// ```
class Capture {
  /// Intercepts print() and debugPrint() output and forwards it to the logger.
  ///
  /// This method replaces Flutter's global [debugPrint] function with a wrapper
  /// that captures the output and sends it to the provided [logger] while
  /// preserving the original behavior (output still appears in system console).
  ///
  /// All captured print output is tagged with 'print' and logged at debug level.
  /// This is appropriate since print statements are typically used for
  /// development debugging rather than production logging.
  ///
  /// Parameters:
  /// * [logger] - The BackstageLogger instance to receive captured output
  ///
  /// **Behavior**:
  /// * Preserves original debugPrint functionality completely
  /// * Adds captured output to logger with debug level
  /// * Handles null messages gracefully (no-op)
  /// * Maintains original wrapWidth parameter behavior
  ///
  /// **Thread Safety**: Safe to call from any isolate. The hook affects
  /// the global debugPrint function across all isolates.
  ///
  /// Example:
  /// ```dart
  /// final logger = BackstageLogger();
  /// Capture.hookPrint(logger);
  /// 
  /// // These will now appear in both system console and Backstage
  /// print('Application starting');
  /// debugPrint('Debug information', wrapWidth: 80);
  /// ```
  ///
  /// **Note**: This should be called early in app initialization, ideally
  /// during or immediately after Backstage.init() to capture all subsequent
  /// print output.
  static void hookPrint(BackstageLogger logger) {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logger.add(BackstageLog(
            message: message, level: BackstageLevel.debug, tag: 'print'));
      }
      original(message, wrapWidth: wrapWidth);
    };
  }

  /// Intercepts Flutter framework errors and forwards them to the logger.
  ///
  /// This method hooks into Flutter's global error handling mechanism by
  /// replacing [FlutterError.onError] with a wrapper that captures error
  /// details and sends them to the provided [logger] while preserving any
  /// existing error handling behavior.
  ///
  /// Captured errors include widget build errors, render errors, gesture
  /// handling errors, and other framework-level exceptions that Flutter
  /// normally only displays in development mode.
  ///
  /// Parameters:
  /// * [logger] - The BackstageLogger instance to receive captured errors
  ///
  /// **Captured Information**:
  /// * Error message from [FlutterErrorDetails.exceptionAsString]
  /// * Full stack trace from [FlutterErrorDetails.stack]
  /// * Tagged with 'flutter' for easy filtering
  /// * Logged at error level for appropriate severity
  ///
  /// **Behavior**:
  /// * Preserves any existing FlutterError.onError handler
  /// * Chain-calls the previous handler after logging
  /// * Does not suppress or modify the original error handling
  ///
  /// **Thread Safety**: Safe to call from the main isolate. Flutter error
  /// handling is single-threaded and occurs on the main isolate.
  ///
  /// Example:
  /// ```dart
  /// final logger = BackstageLogger();
  /// Capture.hookFlutterErrors(logger);
  /// 
  /// // Framework errors will now appear in Backstage console
  /// // For example, widget build errors, overflow errors, etc.
  /// ```
  ///
  /// **Integration**: This is automatically configured when
  /// `BackstageConfig.captureFlutterErrors` is set to `true` during
  /// initialization. Manual calling is only needed for custom setups.
  ///
  /// **Note**: This should be called early in app initialization, ideally
  /// during Backstage.init() to capture all framework errors throughout
  /// the application lifecycle.
  static void hookFlutterErrors(BackstageLogger logger) {
    final prev = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.add(BackstageLog(
        message: details.exceptionAsString(),
        level: BackstageLevel.error,
        tag: 'flutter',
        stackTrace: details.stack,
      ));
      prev?.call(details);
    };
  }
}
