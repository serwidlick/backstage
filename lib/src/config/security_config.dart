/// Security, privacy, and data sanitization configuration.
///
/// This file defines configuration options for protecting sensitive information,
/// controlling access to the debugging console, and ensuring that logged data
/// complies with privacy and security requirements.
library;

/// Configuration options for security, privacy, and data protection.
///
/// [SecurityConfig] specifies how sensitive information should be handled,
/// what access controls should be enforced, and how logged data should be
/// sanitized to prevent exposure of confidential information.
///
/// **Security Principles**:
/// * **Defense in Depth**: Multiple layers of protection
/// * **Least Privilege**: Minimal data exposure necessary for debugging
/// * **Data Sanitization**: Remove or mask sensitive information
/// * **Access Control**: Authenticate and authorize console access
/// * **Compliance**: Meet regulatory and organizational requirements
///
/// **Privacy Considerations**:
/// * Personal data (PII) should be sanitized or excluded
/// * Authentication credentials must never be logged
/// * Business-sensitive data should be protected
/// * Comply with GDPR, CCPA, and other privacy regulations
///
/// Example configurations:
/// ```dart
/// // Development configuration (relaxed security)
/// const devConfig = SecurityConfig(
///   sanitizePatterns: ['password=.*'], // Basic password protection
///   requireAuthentication: false,
///   allowDataExport: true,
/// );
///
/// // Production configuration (strict security)
/// const prodConfig = SecurityConfig(
///   sanitizePatterns: [
///     r'password["\s]*[:=]["\s]*[^"\s,}]+',
///     r'token["\s]*[:=]["\s]*[^"\s,}]+',
///     r'\b\d{3}-\d{2}-\d{4}\b', // SSN
///     r'\b\d{16}\b',            // Credit card
///   ],
///   requireAuthentication: true,
///   allowDataExport: false,
///   sessionTimeoutMinutes: 15,
///   maxFailedAttempts: 3,
/// );
/// ```
class SecurityConfig {
  /// Regular expressions for identifying and sanitizing sensitive data.
  ///
  /// Content matching these patterns will be replaced with '[SANITIZED]'
  /// across all logged data including log messages, network requests,
  /// error details, and exported data.
  ///
  /// **Default**: Basic password and token patterns
  /// **Security**: Essential for preventing credential exposure
  ///
  /// Common patterns:
  /// ```dart
  /// [
  ///   r'password["\s]*[:=]["\s]*[^"\s,}]+',    // JSON/form passwords
  ///   r'token["\s]*[:=]["\s]*[^"\s,}]+',       // API tokens
  ///   r'key["\s]*[:=]["\s]*[^"\s,}]+',         // API keys
  ///   r'\b\d{3}-\d{2}-\d{4}\b',                // Social Security Numbers
  ///   r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', // Credit cards
  ///   r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email
  /// ]
  /// ```
  final List<String> sanitizePatterns;

  /// Whether to require user authentication before accessing the console.
  ///
  /// When enabled, users must provide valid credentials (passcode and/or
  /// biometric authentication) before the console interface becomes
  /// accessible. This provides an additional security layer beyond
  /// the activation gesture.
  ///
  /// **Default**: `true`
  /// **Security**: Recommended for production environments
  final bool requireAuthentication;

  /// Whether to allow export of log data from the console.
  ///
  /// When disabled, users cannot export or share log data through the
  /// console interface, preventing potential data leakage. This is
  /// recommended for production environments with sensitive data.
  ///
  /// **Default**: `true`
  /// **Security**: Consider disabling in production environments
  final bool allowDataExport;

  /// Maximum number of failed authentication attempts before lockout.
  ///
  /// After this many failed attempts to access the console, further
  /// attempts will be blocked for the duration specified by
  /// [lockoutDurationMinutes]. Set to null to disable lockout.
  ///
  /// **Default**: `5`
  /// **Security**: Prevents brute force attacks on console access
  final int? maxFailedAttempts;

  /// Duration in minutes to lock out console access after failed attempts.
  ///
  /// After exceeding [maxFailedAttempts], console access will be blocked
  /// for this duration. This prevents repeated brute force attempts
  /// and provides time for security response.
  ///
  /// **Default**: `15` (15 minutes)
  /// **Security**: Balance between security and usability
  final int lockoutDurationMinutes;

  /// Session timeout in minutes for console access.
  ///
  /// After this period of inactivity, the console will automatically
  /// disable itself and require re-authentication. This prevents
  /// unauthorized access to an unlocked device.
  ///
  /// **Default**: `null` (no timeout)
  /// **Security**: Recommended for production environments
  final int? sessionTimeoutMinutes;

  /// Whether to log security events and access attempts.
  ///
  /// When enabled, console activation attempts, authentication events,
  /// and security violations will be logged for security monitoring
  /// and incident response purposes.
  ///
  /// **Default**: `true`
  /// **Security**: Essential for security monitoring and compliance
  final bool logSecurityEvents;

  /// List of log levels that should not be displayed in the console.
  ///
  /// Logs at these levels will be captured but not shown in the UI,
  /// allowing sensitive debug information to be excluded from
  /// casual viewing while still being available for export/analysis.
  ///
  /// **Default**: `[]` (show all levels)
  /// **Security**: Use to hide sensitive debug information
  final List<String> excludeLogLevels;

  /// List of log tags that should not be displayed in the console.
  ///
  /// Logs with these tags will be captured but not shown in the UI,
  /// allowing sensitive subsystems (authentication, payment processing)
  /// to be excluded from casual viewing.
  ///
  /// **Default**: `[]` (show all tags)
  /// **Security**: Use to hide sensitive subsystem logs
  final List<String> excludeLogTags;

  /// Maximum size in characters for individual log entries.
  ///
  /// Log entries exceeding this size will be truncated to prevent
  /// extremely large logs from consuming excessive memory or revealing
  /// large amounts of potentially sensitive data.
  ///
  /// **Default**: `10000` (10KB)
  /// **Performance**: Prevents memory issues with large log entries
  final int maxLogEntrySize;

  /// Whether to require device screen lock to access the console.
  ///
  /// When enabled, the device must have a screen lock (PIN, pattern,
  /// password, biometric) configured and active before the console
  /// can be accessed. This ensures basic device security.
  ///
  /// **Default**: `false`
  /// **Security**: Additional security layer for sensitive environments
  final bool requireDeviceScreenLock;

  /// List of network domains that should not have their requests logged.
  ///
  /// HTTP requests to these domains will be excluded from network
  /// logging to prevent exposure of requests to sensitive services
  /// like authentication providers or payment processors.
  ///
  /// **Default**: `[]` (log all domains)
  /// **Security**: Protect sensitive third-party integrations
  ///
  /// Example domains:
  /// ```dart
  /// [
  ///   'auth.company.com',
  ///   'payments.stripe.com',
  ///   'api.oauth.provider.com',
  /// ]
  /// ```
  final List<String> excludeNetworkDomains;

  /// Whether to automatically sanitize known PII patterns.
  ///
  /// When enabled, common personally identifiable information patterns
  /// (email addresses, phone numbers, etc.) will be automatically
  /// sanitized even if not explicitly listed in [sanitizePatterns].
  ///
  /// **Default**: `true`
  /// **Privacy**: Helps ensure GDPR/CCPA compliance
  final bool autoSanitizePII;

  /// Custom replacement text for sanitized content.
  ///
  /// This text will replace sanitized content instead of the default
  /// '[SANITIZED]' marker. Useful for organizational compliance
  /// requirements or debugging clarity.
  ///
  /// **Default**: `'[SANITIZED]'`
  /// **Customization**: Align with organizational standards
  final String sanitizationReplacement;

  /// Whether to hash user identifiers for privacy protection.
  ///
  /// When enabled, user IDs and other identifiers will be consistently
  /// hashed to allow correlation while protecting actual user identity.
  /// This enables debugging user-specific issues without exposing PII.
  ///
  /// **Default**: `false`
  /// **Privacy**: Enables user correlation without identity exposure
  final bool hashUserIdentifiers;

  /// Salt for hashing user identifiers (required if hashUserIdentifiers is true).
  ///
  /// A unique salt value used for hashing user identifiers. Should be
  /// randomly generated and consistent across app sessions to allow
  /// correlation of hashed identifiers.
  ///
  /// **Default**: `null`
  /// **Security**: Use a cryptographically secure random salt
  final String? hashingSalt;

  /// Creates a new security configuration with the specified options.
  ///
  /// All parameters are optional and have security-conscious defaults
  /// that provide reasonable protection while maintaining debugging utility.
  /// Adjust based on your specific security and compliance requirements.
  ///
  /// Example:
  /// ```dart
  /// const config = SecurityConfig(
  ///   sanitizePatterns: [
  ///     r'password["\s]*[:=]["\s]*[^"\s,}]+',
  ///     r'token["\s]*[:=]["\s]*[^"\s,}]+',
  ///     r'\b\d{3}-\d{2}-\d{4}\b', // SSN
  ///   ],
  ///   requireAuthentication: true,
  ///   allowDataExport: false,
  ///   maxFailedAttempts: 3,
  ///   sessionTimeoutMinutes: 30,
  ///   autoSanitizePII: true,
  /// );
  /// ```
  const SecurityConfig({
    this.sanitizePatterns = const [
      r'password["\s]*[:=]["\s]*[^"\s,}]+',
      r'token["\s]*[:=]["\s]*[^"\s,}]+',
      r'key["\s]*[:=]["\s]*[^"\s,}]+',
      r'secret["\s]*[:=]["\s]*[^"\s,}]+',
    ],
    this.requireAuthentication = true,
    this.allowDataExport = true,
    this.maxFailedAttempts = 5,
    this.lockoutDurationMinutes = 15,
    this.sessionTimeoutMinutes,
    this.logSecurityEvents = true,
    this.excludeLogLevels = const [],
    this.excludeLogTags = const [],
    this.maxLogEntrySize = 10000,
    this.requireDeviceScreenLock = false,
    this.excludeNetworkDomains = const [],
    this.autoSanitizePII = true,
    this.sanitizationReplacement = '[SANITIZED]',
    this.hashUserIdentifiers = false,
    this.hashingSalt,
  });
}
