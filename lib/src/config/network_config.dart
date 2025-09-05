/// Network monitoring and HTTP interception configuration.
///
/// This file defines configuration options for network request logging,
/// including what data to capture, filtering rules, and security considerations
/// for HTTP request and response monitoring.
library;

/// Configuration options for network request logging and monitoring.
///
/// [NetworkConfig] specifies how HTTP requests and responses should be
/// captured, logged, and displayed in the Backstage console. It provides
/// granular control over what data is collected to balance debugging
/// utility with security and privacy requirements.
///
/// **Security Considerations**:
/// * [captureHeaders] may expose authentication tokens
/// * [captureRequestBody] and [captureResponseBody] may contain sensitive data
/// * Use [headerSanitization] and [bodySanitization] patterns to protect secrets
/// * Consider different configurations for development vs production
///
/// **Performance Impact**:
/// * Capturing large request/response bodies can impact memory usage
/// * Set [maxBodySize] to limit memory consumption
/// * Body capture adds processing overhead for each request
///
/// Example configurations:
/// ```dart
/// // Development configuration (full logging)
/// const devConfig = NetworkConfig(
///   captureHeaders: true,
///   captureRequestBody: true,
///   captureResponseBody: true,
///   captureTiming: true,
/// );
///
/// // Production configuration (security-focused)
/// const prodConfig = NetworkConfig(
///   captureHeaders: false, // Avoid logging auth tokens
///   captureRequestBody: false,
///   captureResponseBody: false,
///   captureTiming: true,
///   captureErrors: true,
///   headerSanitization: ['authorization', 'x-api-key'],
/// );
/// ```
class NetworkConfig {
  /// Whether to capture HTTP request headers.
  ///
  /// When enabled, all request headers will be logged and displayed
  /// in the network tab. This can be useful for debugging API calls
  /// but may expose sensitive authentication information.
  ///
  /// **Default**: `false`
  /// **Security**: May expose authentication tokens and API keys
  final bool captureHeaders;

  /// Whether to capture HTTP response headers.
  ///
  /// When enabled, all response headers will be logged and displayed.
  /// Response headers typically contain less sensitive information
  /// than request headers but may still include session cookies.
  ///
  /// **Default**: `false`
  /// **Security**: May expose session information and server details
  final bool captureResponseHeaders;

  /// Whether to capture HTTP request body content.
  ///
  /// When enabled, the full request body (JSON, form data, etc.)
  /// will be captured and displayed. This is extremely useful for
  /// debugging API calls but can expose highly sensitive data.
  ///
  /// **Default**: `false`
  /// **Security**: May expose passwords, personal data, and business logic
  /// **Performance**: Large request bodies impact memory usage
  final bool captureRequestBody;

  /// Whether to capture HTTP response body content.
  ///
  /// When enabled, the full response body will be captured and
  /// displayed. This helps with debugging API responses but can
  /// consume significant memory for large responses.
  ///
  /// **Default**: `false`
  /// **Performance**: Large response bodies impact memory usage
  /// **Security**: May expose sensitive business data
  final bool captureResponseBody;

  /// Whether to capture request/response timing information.
  ///
  /// When enabled, detailed timing metrics including DNS resolution,
  /// connection establishment, request transmission, and response
  /// reception times will be captured and displayed.
  ///
  /// **Default**: `true`
  /// **Performance**: Minimal overhead, useful for performance debugging
  final bool captureTiming;

  /// Whether to capture network errors and failures.
  ///
  /// When enabled, network errors, timeouts, connection failures,
  /// and HTTP error status codes will be captured with detailed
  /// error information for debugging connectivity issues.
  ///
  /// **Default**: `true`
  /// **Utility**: Essential for debugging network connectivity problems
  final bool captureErrors;

  /// Maximum size in bytes for captured request/response bodies.
  ///
  /// Bodies larger than this size will be truncated to prevent
  /// excessive memory usage. Set to null for no limit (not recommended
  /// in production).
  ///
  /// **Default**: `1048576` (1MB)
  /// **Performance**: Prevents memory issues with large payloads
  final int? maxBodySize;

  /// List of header names to sanitize (case-insensitive).
  ///
  /// Headers matching these names will have their values replaced
  /// with '[SANITIZED]' to prevent exposure of sensitive authentication
  /// information while still showing that the header was present.
  ///
  /// **Default**: `['authorization', 'cookie', 'x-api-key']`
  /// **Security**: Essential for protecting authentication credentials
  final List<String> headerSanitization;

  /// Regular expressions for sanitizing request/response body content.
  ///
  /// Body content matching these patterns will be replaced with
  /// '[SANITIZED]' to remove sensitive data while preserving
  /// the overall structure for debugging.
  ///
  /// **Default**: `[]` (no sanitization)
  /// **Security**: Use to protect passwords, tokens, and personal data
  ///
  /// Example patterns:
  /// ```dart
  /// [
  ///   r'"password"\s*:\s*"[^"]*"', // JSON password fields
  ///   r'"token"\s*:\s*"[^"]*"',    // JSON token fields
  ///   r'ssn=\d{3}-\d{2}-\d{4}',   // Social security numbers
  /// ]
  /// ```
  final List<String> bodySanitization;

  /// List of URL patterns to exclude from network logging.
  ///
  /// Requests to URLs matching these patterns (case-insensitive substring
  /// matching) will not be logged at all. Useful for excluding internal
  /// health checks, analytics, or other noise from the network log.
  ///
  /// **Default**: `[]` (capture all requests)
  ///
  /// Example exclusions:
  /// ```dart
  /// [
  ///   '/health',           // Health check endpoints
  ///   'analytics.google',  // Analytics requests
  ///   '.well-known/',      // Well-known endpoints
  /// ]
  /// ```
  final List<String> excludeUrls;

  /// List of URL patterns to specifically include in network logging.
  ///
  /// When non-empty, only requests to URLs matching these patterns
  /// will be logged. Takes precedence over [excludeUrls]. Useful
  /// for focusing on specific API endpoints during debugging.
  ///
  /// **Default**: `[]` (include all requests, subject to exclusions)
  ///
  /// Example inclusions:
  /// ```dart
  /// [
  ///   '/api/',             // Only API endpoints
  ///   'myservice.com',     // Only specific domain
  /// ]
  /// ```
  final List<String> includeOnlyUrls;

  /// Whether to capture WebSocket connections and messages.
  ///
  /// When enabled, WebSocket connection events and message content
  /// will be captured and displayed in the network tab alongside
  /// HTTP requests.
  ///
  /// **Default**: `false`
  /// **Performance**: WebSocket message capture can be high-volume
  final bool captureWebSockets;

  /// Maximum number of network requests to retain in memory.
  ///
  /// Older requests will be automatically removed to prevent
  /// unlimited memory growth. Set to null for no limit (not
  /// recommended for long-running applications).
  ///
  /// **Default**: `1000`
  /// **Performance**: Prevents memory leaks in long-running apps
  final int? maxRequestHistory;

  /// Creates a new network configuration with the specified options.
  ///
  /// All parameters are optional and have security-conscious defaults
  /// that minimize data exposure while still providing basic network
  /// monitoring capabilities.
  ///
  /// Example:
  /// ```dart
  /// const config = NetworkConfig(
  ///   captureHeaders: kDebugMode, // Only in debug builds
  ///   captureRequestBody: false,   // Never capture request bodies
  ///   captureResponseBody: false,  // Never capture response bodies
  ///   captureTiming: true,         // Always capture timing
  ///   captureErrors: true,         // Always capture errors
  ///   headerSanitization: [
  ///     'authorization',
  ///     'x-api-key',
  ///     'cookie',
  ///   ],
  /// );
  /// ```
  const NetworkConfig({
    this.captureHeaders = false,
    this.captureResponseHeaders = false,
    this.captureRequestBody = false,
    this.captureResponseBody = false,
    this.captureTiming = true,
    this.captureErrors = true,
    this.maxBodySize = 1048576, // 1MB
    this.headerSanitization = const [
      'authorization',
      'cookie',
      'x-api-key',
      'x-auth-token',
      'bearer',
    ],
    this.bodySanitization = const [],
    this.excludeUrls = const [],
    this.includeOnlyUrls = const [],
    this.captureWebSockets = false,
    this.maxRequestHistory = 1000,
  });
}
