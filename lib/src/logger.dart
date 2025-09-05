/// Core logging functionality for the Backstage debugging console.
///
/// This file contains the primary logging classes and utilities used
/// throughout the Backstage package for capturing and managing log
/// entries in production Flutter applications.
///
/// The main components are:
/// * [BackstageLogger] - The primary logging interface
/// * [BackstageLog] - Individual log entry data structure
/// * [BackstageLevel] - Log severity levels
/// * [BackstageTag] - Type alias for log categorization
library;

import 'dart:async';

/// Type alias for log categorization tags.
///
/// Tags are used to categorize log entries and enable filtering in the
/// debugging console. Common tags include 'auth', 'network', 'database',
/// and 'ui'. The default tag is 'app' for general application logs.
///
/// Example usage:
/// ```dart
/// const BackstageTag authTag = 'authentication';
/// logger.i('User login successful', tag: authTag);
/// ```
typedef BackstageTag = String;

/// Enumeration of available log severity levels.
///
/// Log levels are ordered by severity from lowest ([debug]) to highest ([error]).
/// The logging console can filter entries based on minimum severity level,
/// showing only logs at or above the selected threshold.
///
/// Level descriptions:
/// * [debug] - Detailed information for diagnosing problems
/// * [info] - General informational messages about application flow
/// * [warn] - Warning messages for potentially harmful situations
/// * [error] - Error events that might still allow application to continue
enum BackstageLevel {
  /// Detailed diagnostic information, typically only of interest when diagnosing problems.
  debug,

  /// Informational messages that highlight application progress at a coarse-grained level.
  info,

  /// Potentially harmful situations that deserve attention but don't prevent continued execution.
  warn,

  /// Error events that might still allow the application to continue running.
  error
}

/// Immutable data structure representing a single log entry.
///
/// Each [BackstageLog] instance captures a complete log event including
/// the message content, severity level, categorization tag, timestamp,
/// and optional stack trace for debugging context.
///
/// The timestamp is automatically set to the current time when the log
/// entry is created, unless explicitly provided during construction.
///
/// Example usage:
/// ```dart
/// final log = BackstageLog(
///   message: 'Database connection established',
///   level: BackstageLevel.info,
///   tag: 'database',
/// );
/// ```
///
/// For error logs with stack traces:
/// ```dart
/// final errorLog = BackstageLog(
///   message: 'Failed to process user request',
///   level: BackstageLevel.error,
///   tag: 'api',
///   stackTrace: StackTrace.current,
/// );
/// ```
class BackstageLog {
  /// The timestamp when this log entry was created.
  ///
  /// Automatically set to [DateTime.now] during construction unless
  /// explicitly provided. Used for chronological ordering and display
  /// in the debugging console.
  final DateTime time;

  /// The primary log message content.
  ///
  /// Should be a clear, concise description of the logged event.
  /// Avoid including sensitive information like passwords or tokens.
  final String message;

  /// The severity level of this log entry.
  ///
  /// Determines how this log is categorized and whether it appears
  /// when filtering by minimum log level in the debugging console.
  final BackstageLevel level;

  /// The categorization tag for this log entry.
  ///
  /// Used to group related log entries and enable filtering by
  /// functional area. Defaults to 'app' if not specified.
  final BackstageTag tag;

  /// Optional stack trace providing debugging context.
  ///
  /// Typically included with error and warning logs to help
  /// identify the source location and call path that led to
  /// the logged event. Can be null for informational logs.
  final StackTrace? stackTrace;

  /// Creates a new log entry with the specified parameters.
  ///
  /// The [message] and [level] are required. The [tag] defaults to 'app'
  /// and [time] defaults to the current timestamp if not provided.
  ///
  /// The [stackTrace] is optional and typically used for error logs
  /// to provide debugging context about the source of the problem.
  ///
  /// Example:
  /// ```dart
  /// final log = BackstageLog(
  ///   message: 'User authentication failed',
  ///   level: BackstageLevel.warn,
  ///   tag: 'auth',
  ///   stackTrace: StackTrace.current,
  /// );
  /// ```
  BackstageLog({
    required this.message,
    required this.level,
    this.tag = 'app',
    this.stackTrace,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

/// A comprehensive logging system for capturing application events and errors.
///
/// [BackstageLogger] provides structured logging capabilities with support
/// for multiple log levels, custom tags, and stack trace capture. It uses a
/// broadcast stream architecture to allow multiple listeners to consume log
/// events simultaneously.
///
/// The logger is thread-safe and can be used from any isolate. All log entries
/// are immediately broadcast to subscribers through the [stream] property.
///
/// Basic usage example:
/// ```dart
/// final logger = BackstageLogger();
///
/// // Subscribe to log events
/// logger.stream.listen((log) {
///   print('${log.level.name}: ${log.message}');
/// });
///
/// // Log messages at different levels
/// logger.i('Application started successfully');
/// logger.w('Low memory warning', tag: 'system');
/// logger.e('Database connection failed', tag: 'db');
/// ```
///
/// The logger provides convenience methods for each log level:
/// * [d] for debug messages
/// * [i] for informational messages
/// * [w] for warnings
/// * [e] for errors (with optional stack trace)
///
/// See also:
/// * [BackstageLog] for the log entry data structure
/// * [BackstageLevel] for available severity levels
/// * [BackstageTag] for categorization options
class BackstageLogger {
  /// Internal stream controller for broadcasting log events.
  ///
  /// Uses broadcast mode to support multiple simultaneous listeners.
  /// The controller is never closed during the logger's lifetime to
  /// ensure continuous availability for log consumption.
  final _controller = StreamController<BackstageLog>.broadcast();

  /// A broadcast stream that emits all log entries added to this logger.
  ///
  /// Multiple listeners can subscribe to this stream simultaneously. Each
  /// listener receives all log entries from the time they subscribe. The
  /// stream never closes unless the logger is explicitly disposed.
  ///
  /// Use this stream to build custom log viewers, filters, or persistence
  /// layers on top of the core logging functionality.
  ///
  /// Example usage:
  /// ```dart
  /// final logger = BackstageLogger();
  ///
  /// // Listen for all log entries
  /// logger.stream.listen((log) {
  ///   if (log.level == BackstageLevel.error) {
  ///     sendErrorToMonitoring(log);
  ///   }
  /// });
  ///
  /// // Listen for specific tags only
  /// logger.stream
  ///   .where((log) => log.tag == 'network')
  ///   .listen(handleNetworkLogs);
  /// ```
  Stream<BackstageLog> get stream => _controller.stream;

  /// Adds a new log entry to the stream and notifies all listeners.
  ///
  /// The [log] parameter contains the complete log information including
  /// timestamp, message, level, and optional stack trace. The log is
  /// immediately broadcast to all active stream subscribers.
  ///
  /// This method is thread-safe and can be called from any isolate.
  ///
  /// Example:
  /// ```dart
  /// logger.add(BackstageLog(
  ///   message: 'Operation completed successfully',
  ///   level: BackstageLevel.info,
  ///   tag: 'operation',
  /// ));
  /// ```
  void add(BackstageLog log) => _controller.add(log);

  /// Logs a debug message with optional categorization tag.
  ///
  /// Debug messages are intended for detailed diagnostic information,
  /// typically only of interest when diagnosing problems. These logs
  /// may be filtered out in production environments.
  ///
  /// Parameters:
  /// * [msg] - The debug message content
  /// * [tag] - Optional categorization tag (defaults to 'app')
  ///
  /// Example:
  /// ```dart
  /// logger.d('Processing user input: $input', tag: 'ui');
  /// logger.d('Cache hit for key: $cacheKey', tag: 'cache');
  /// ```
  void d(String msg, {BackstageTag tag = 'app'}) =>
      add(BackstageLog(message: msg, level: BackstageLevel.debug, tag: tag));

  /// Logs an informational message with optional categorization tag.
  ///
  /// Info messages highlight application progress at a coarse-grained level.
  /// These are typically the most common type of log entry and provide
  /// insight into normal application flow.
  ///
  /// Parameters:
  /// * [msg] - The informational message content
  /// * [tag] - Optional categorization tag (defaults to 'app')
  ///
  /// Example:
  /// ```dart
  /// logger.i('User logged in successfully', tag: 'auth');
  /// logger.i('Background sync completed', tag: 'sync');
  /// ```
  void i(String msg, {BackstageTag tag = 'app'}) =>
      add(BackstageLog(message: msg, level: BackstageLevel.info, tag: tag));

  /// Logs a warning message with optional categorization tag.
  ///
  /// Warning messages indicate potentially harmful situations that deserve
  /// attention but don't prevent continued execution. These often indicate
  /// configuration issues, deprecated API usage, or recoverable errors.
  ///
  /// Parameters:
  /// * [msg] - The warning message content
  /// * [tag] - Optional categorization tag (defaults to 'app')
  ///
  /// Example:
  /// ```dart
  /// logger.w('API rate limit approaching', tag: 'network');
  /// logger.w('Deprecated method called', tag: 'compatibility');
  /// ```
  void w(String msg, {BackstageTag tag = 'app'}) =>
      add(BackstageLog(message: msg, level: BackstageLevel.warn, tag: tag));

  /// Logs an error message with optional categorization tag and stack trace.
  ///
  /// Error messages indicate problems that might still allow the application
  /// to continue running. Include a stack trace when possible to aid in
  /// debugging and problem resolution.
  ///
  /// Parameters:
  /// * [msg] - The error message content
  /// * [tag] - Optional categorization tag (defaults to 'app')
  /// * [st] - Optional stack trace for debugging context
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await performNetworkRequest();
  /// } catch (e, stackTrace) {
  ///   logger.e('Network request failed: $e', tag: 'network', st: stackTrace);
  /// }
  /// ```
  void e(String msg, {BackstageTag tag = 'app', StackTrace? st}) =>
      add(BackstageLog(
          message: msg, level: BackstageLevel.error, tag: tag, stackTrace: st));
}
