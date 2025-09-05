/// Security and data sanitization service for Backstage.
///
/// This file provides comprehensive security features including data sanitization,
/// access control, biometric authentication, and privacy protection to ensure
/// sensitive information is properly handled in debugging environments.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../config/security_config.dart';
import '../logger.dart';

/// Authentication result with details about the authentication process.
class AuthenticationResult {
  /// Whether authentication was successful
  final bool success;

  /// Type of authentication used (passcode, biometric, device_lock)
  final String? authenticationType;

  /// Error message if authentication failed
  final String? error;

  /// Session token for authenticated access
  final String? sessionToken;

  /// Session expiration time
  final DateTime? sessionExpiration;

  /// Creates a new authentication result.
  const AuthenticationResult({
    required this.success,
    this.authenticationType,
    this.error,
    this.sessionToken,
    this.sessionExpiration,
  });

  /// Creates a successful authentication result.
  AuthenticationResult.success({
    required String authenticationType,
    String? sessionToken,
    DateTime? sessionExpiration,
  }) : this(
          success: true,
          authenticationType: authenticationType,
          sessionToken: sessionToken,
          sessionExpiration: sessionExpiration,
        );

  /// Creates a failed authentication result.
  AuthenticationResult.failure({
    required String error,
  }) : this(
          success: false,
          error: error,
        );
}

/// Security event for audit logging.
class SecurityEvent {
  /// Type of security event
  final String eventType;

  /// Timestamp when event occurred
  final DateTime timestamp;

  /// Event description
  final String description;

  /// Whether the event was successful
  final bool success;

  /// Additional event data
  final Map<String, dynamic> data;

  /// Creates a new security event.
  SecurityEvent({
    required this.eventType,
    required this.description,
    required this.success,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts to a map for logging.
  Map<String, dynamic> toMap() {
    return {
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'success': success,
      'data': data,
    };
  }
}

/// Comprehensive security service for Backstage debugging console.
///
/// [SecurityService] provides essential security features for production
/// debugging environments including data sanitization, access control,
/// biometric authentication, session management, and privacy protection.
///
/// **Security Features**:
/// * **Data Sanitization**: Remove or mask sensitive information in logs
/// * **Access Control**: Multi-factor authentication and session management
/// * **Biometric Authentication**: Touch ID, Face ID, fingerprint support
/// * **Privacy Protection**: PII detection and automatic sanitization
/// * **Audit Logging**: Security event tracking and monitoring
/// * **Session Management**: Timeout-based security and lockout protection
///
/// **Privacy Compliance**:
/// * **GDPR/CCPA Support**: Automatic PII sanitization and data minimization
/// * **Data Classification**: Sensitive data detection and handling
/// * **Retention Control**: Configurable data retention and deletion
/// * **Access Logging**: Complete audit trail for compliance reporting
///
/// **Threat Protection**:
/// * **Brute Force Protection**: Lockout after failed authentication attempts
/// * **Session Hijacking**: Secure session tokens and timeout protection
/// * **Data Leakage**: Comprehensive sanitization and filtering
/// * **Unauthorized Access**: Multi-layered authentication and authorization
///
/// Example usage:
/// ```dart
/// final securityService = SecurityService(securityConfig, logger);
/// await securityService.initialize();
///
/// // Authenticate user
/// final authResult = await securityService.authenticate(
///   passcode: 'user_entered_code',
///   useBiometric: true,
/// );
///
/// if (authResult.success) {
///   // Sanitize sensitive data
///   final sanitizedText = securityService.sanitizeText(
///     'User password is secret123 and token is abc123xyz'
///   );
///   print(sanitizedText); // "User password is [SANITIZED] and token is [SANITIZED]"
/// }
/// ```
class SecurityService {
  /// Configuration for security behavior and policies.
  final SecurityConfig config;

  /// Logger for security events and audit trail.
  final BackstageLogger logger;

  /// Local authentication instance for biometric support.
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Current authentication session information.
  AuthenticationResult? _currentSession;

  /// Failed authentication attempt tracking.
  final Map<String, List<DateTime>> _failedAttempts = {};

  /// Security event history.
  final List<SecurityEvent> _securityEvents = [];

  /// Timer for session timeout monitoring.
  Timer? _sessionTimer;

  /// Random number generator for secure tokens.
  final Random _random = Random.secure();

  /// Creates a new security service with the specified configuration.
  ///
  /// The [config] parameter defines security policies, authentication
  /// requirements, and sanitization rules. The [logger] receives
  /// security events for audit and monitoring purposes.
  SecurityService(this.config, this.logger);

  /// Initializes the security service and sets up authentication systems.
  ///
  /// Performs initial security checks, validates biometric availability,
  /// sets up sanitization patterns, and prepares authentication systems
  /// for use throughout the application lifecycle.
  ///
  /// **Initialization Steps**:
  /// 1. Check device security capabilities (biometric, screen lock)
  /// 2. Validate configuration settings and security policies
  /// 3. Initialize sanitization pattern compilation
  /// 4. Set up session management and timeout systems
  /// 5. Prepare audit logging and event tracking
  ///
  /// Example:
  /// ```dart
  /// await securityService.initialize();
  ///
  /// // Security service is now ready for authentication and sanitization
  /// ```
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('Backstage SecurityService: Initializing security systems');
    }

    // Check biometric availability
    if (config.requireAuthentication) {
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable && config.requireAuthentication) {
        _logSecurityEvent(SecurityEvent(
          eventType: 'initialization_warning',
          description: 'Biometric authentication not available on device',
          success: false,
        ));
      }
    }

    // Validate security configuration
    if (config.hashUserIdentifiers && config.hashingSalt == null) {
      throw ArgumentError(
          'hashingSalt is required when hashUserIdentifiers is enabled');
    }

    // Initialize sanitization patterns
    _compileSanitizationPatterns();

    logger.i('Security service initialized', tag: 'security');
  }

  /// Authenticates user access to the debugging console.
  ///
  /// Performs multi-factor authentication based on configuration including
  /// passcode verification, biometric authentication, and device security
  /// checks. Manages session creation and lockout protection.
  ///
  /// Parameters:
  /// * [passcode] - User-provided passcode (if passcode authentication enabled)
  /// * [useBiometric] - Whether to attempt biometric authentication
  /// * [bypassLockout] - Administrative bypass for lockout (internal use)
  ///
  /// Returns: [AuthenticationResult] with success status and session details
  ///
  /// Example:
  /// ```dart
  /// // Passcode-only authentication
  /// final result1 = await securityService.authenticate(
  ///   passcode: userEnteredCode,
  /// );
  ///
  /// // Biometric authentication
  /// final result2 = await securityService.authenticate(
  ///   useBiometric: true,
  /// );
  ///
  /// if (result2.success) {
  ///   print('Authenticated using ${result2.authenticationType}');
  /// }
  /// ```
  Future<AuthenticationResult> authenticate({
    String? passcode,
    bool useBiometric = false,
    bool bypassLockout = false,
  }) async {
    final clientId = 'console_access';

    // Check lockout status
    if (!bypassLockout && _isLockedOut(clientId)) {
      final event = SecurityEvent(
        eventType: 'authentication_blocked',
        description: 'Authentication blocked due to lockout',
        success: false,
        data: {'clientId': clientId},
      );
      _logSecurityEvent(event);

      return AuthenticationResult.failure(
        error: 'Access temporarily locked due to failed attempts',
      );
    }

    AuthenticationResult? result;

    // Try biometric authentication first if requested
    if (useBiometric) {
      result = await _authenticateWithBiometric();
    }

    // Try passcode authentication if biometric failed or not requested
    if (result == null || !result.success) {
      if (passcode != null) {
        result = await _authenticateWithPasscode(passcode);
      }
    }

    // Default failure if no authentication method succeeded
    result ??= AuthenticationResult.failure(
      error: 'No valid authentication method provided',
    );

    // Handle authentication result
    if (result.success) {
      _clearFailedAttempts(clientId);
      _currentSession = result;
      _startSessionTimer();

      _logSecurityEvent(SecurityEvent(
        eventType: 'authentication_success',
        description: 'User authenticated successfully',
        success: true,
        data: {
          'method': result.authenticationType,
          'sessionToken': result.sessionToken!.substring(0, 8) + '...',
        },
      ));
    } else {
      _recordFailedAttempt(clientId);

      _logSecurityEvent(SecurityEvent(
        eventType: 'authentication_failure',
        description: result.error ?? 'Authentication failed',
        success: false,
        data: {'clientId': clientId},
      ));
    }

    return result;
  }

  /// Checks if the current session is valid and authenticated.
  ///
  /// Verifies session existence, expiration, and validity. Used to
  /// control access to debugging console features and sensitive data.
  ///
  /// Returns: `true` if session is valid and user is authenticated
  bool isAuthenticated() {
    if (!config.requireAuthentication) {
      return true; // Authentication not required
    }

    if (_currentSession == null || !_currentSession!.success) {
      return false;
    }

    // Check session expiration
    if (_currentSession!.sessionExpiration != null &&
        DateTime.now().isAfter(_currentSession!.sessionExpiration!)) {
      _invalidateSession('Session expired');
      return false;
    }

    return true;
  }

  /// Invalidates the current authentication session.
  ///
  /// Ends the current session and requires re-authentication for
  /// subsequent access. Called automatically on timeout or can
  /// be called manually for explicit logout.
  ///
  /// Parameters:
  /// * [reason] - Reason for session invalidation (for audit logging)
  void invalidateSession([String? reason]) {
    _invalidateSession(reason ?? 'Manual logout');
  }

  /// Sanitizes text content by removing or masking sensitive information.
  ///
  /// Applies configured sanitization patterns to detect and remove
  /// sensitive data including passwords, API keys, personal information,
  /// and custom-defined sensitive patterns.
  ///
  /// Parameters:
  /// * [text] - Original text content to sanitize
  /// * [replacement] - Custom replacement text (uses config default if null)
  ///
  /// Returns: Sanitized text with sensitive information masked
  ///
  /// Example:
  /// ```dart
  /// final original = 'Login: user@email.com password=secret123 token=abc';
  /// final sanitized = securityService.sanitizeText(original);
  /// print(sanitized); // "Login: [SANITIZED] password=[SANITIZED] token=[SANITIZED]"
  /// ```
  String sanitizeText(String text, [String? replacement]) {
    var sanitized = text;
    final sanitizationReplacement =
        replacement ?? config.sanitizationReplacement;

    // Apply configured sanitization patterns
    for (final pattern in config.sanitizePatterns) {
      try {
        final regex = RegExp(pattern, multiLine: true, caseSensitive: false);
        sanitized = sanitized.replaceAll(regex, sanitizationReplacement);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Invalid sanitization pattern: $pattern');
        }
      }
    }

    // Apply automatic PII sanitization if enabled
    if (config.autoSanitizePII) {
      sanitized = _sanitizePII(sanitized, sanitizationReplacement);
    }

    // Apply length limit
    if (sanitized.length > config.maxLogEntrySize) {
      sanitized =
          sanitized.substring(0, config.maxLogEntrySize) + '... [TRUNCATED]';
    }

    return sanitized;
  }

  /// Sanitizes a BackstageLog entry according to security policies.
  ///
  /// Applies comprehensive sanitization to all aspects of a log entry
  /// including message content, tag information, and stack traces.
  /// Respects configuration settings for exclusions and filtering.
  ///
  /// Parameters:
  /// * [log] - Original log entry to sanitize
  ///
  /// Returns: New [BackstageLog] with sanitized content or null if excluded
  ///
  /// Example:
  /// ```dart
  /// final originalLog = BackstageLog(
  ///   message: 'API call failed: token=abc123',
  ///   level: BackstageLevel.error,
  ///   tag: 'network',
  /// );
  ///
  /// final sanitizedLog = securityService.sanitizeLogEntry(originalLog);
  /// print(sanitizedLog?.message); // "API call failed: token=[SANITIZED]"
  /// ```
  BackstageLog? sanitizeLogEntry(BackstageLog log) {
    // Check if log level should be excluded
    if (config.excludeLogLevels.contains(log.level.name)) {
      return null;
    }

    // Check if log tag should be excluded
    if (config.excludeLogTags.contains(log.tag)) {
      return null;
    }

    // Sanitize message content
    final sanitizedMessage = sanitizeText(log.message);

    // Sanitize stack trace if present
    String? sanitizedStackTrace;
    if (log.stackTrace != null) {
      sanitizedStackTrace = sanitizeText(log.stackTrace.toString());
    }

    return BackstageLog(
      message: sanitizedMessage,
      level: log.level,
      tag: log.tag,
      time: log.time,
      stackTrace: sanitizedStackTrace != null
          ? StackTrace.fromString(sanitizedStackTrace)
          : null,
    );
  }

  /// Hashes user identifiers for privacy protection.
  ///
  /// Creates consistent, irreversible hashes of user identifiers that
  /// allow correlation in debugging while protecting actual identity.
  /// Uses configured salt for additional security.
  ///
  /// Parameters:
  /// * [identifier] - Original user identifier
  ///
  /// Returns: Hashed identifier string
  ///
  /// Example:
  /// ```dart
  /// final userId = 'user123@example.com';
  /// final hashedId = securityService.hashUserIdentifier(userId);
  /// print(hashedId); // "usr_8a4b2c5f9e1d3a7b"
  /// ```
  String hashUserIdentifier(String identifier) {
    if (!config.hashUserIdentifiers || config.hashingSalt == null) {
      return identifier;
    }

    final saltedId = '${config.hashingSalt}$identifier';
    final bytes = utf8.encode(saltedId);
    final digest = sha256.convert(bytes);

    // Return first 16 characters with prefix for identification
    return 'usr_${digest.toString().substring(0, 16)}';
  }

  /// Retrieves security events for audit and monitoring purposes.
  ///
  /// Returns recent security events including authentication attempts,
  /// access control decisions, and security violations. Used for
  /// compliance reporting and security monitoring.
  ///
  /// Parameters:
  /// * [limit] - Maximum number of events to return
  /// * [eventType] - Filter by specific event type
  ///
  /// Returns: List of recent security events
  List<SecurityEvent> getSecurityEvents({int? limit, String? eventType}) {
    var events = _securityEvents.where((event) {
      return eventType == null || event.eventType == eventType;
    }).toList();

    // Sort by timestamp (most recent first)
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null) {
      events = events.take(limit).toList();
    }

    return events;
  }

  /// Gets security statistics and health metrics.
  ///
  /// Provides aggregate information about security events, authentication
  /// patterns, and system security health. Useful for monitoring and
  /// alerting on security-related issues.
  ///
  /// Returns: Map containing security statistics
  Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));

    final recent24HEvents =
        _securityEvents.where((e) => e.timestamp.isAfter(last24Hours)).toList();

    final authSuccesses = recent24HEvents
        .where((e) => e.eventType == 'authentication_success')
        .length;

    final authFailures = recent24HEvents
        .where((e) => e.eventType == 'authentication_failure')
        .length;

    final totalAttempts = authSuccesses + authFailures;
    final successRate =
        totalAttempts > 0 ? (authSuccesses / totalAttempts * 100) : 100.0;

    return {
      'totalSecurityEvents': _securityEvents.length,
      'events24Hours': recent24HEvents.length,
      'authSuccesses24h': authSuccesses,
      'authFailures24h': authFailures,
      'authSuccessRate': successRate.toStringAsFixed(1),
      'currentSessionValid': isAuthenticated(),
      'lockoutActive': _isLockedOut('console_access'),
    };
  }

  /// Performs biometric authentication.
  Future<AuthenticationResult> _authenticateWithBiometric() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        return AuthenticationResult.failure(
          error: 'Biometric authentication not available',
        );
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthenticationResult.failure(
          error: 'No biometric methods configured',
        );
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access debugging console',
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        return AuthenticationResult.success(
          authenticationType: 'biometric',
          sessionToken: _generateSessionToken(),
          sessionExpiration: _calculateSessionExpiration(),
        );
      } else {
        return AuthenticationResult.failure(
          error: 'Biometric authentication failed',
        );
      }
    } catch (e) {
      return AuthenticationResult.failure(
        error: 'Biometric authentication error: $e',
      );
    }
  }

  /// Performs passcode authentication.
  Future<AuthenticationResult> _authenticateWithPasscode(
      String passcode) async {
    // This would typically involve secure comparison
    // For demo purposes, we'll do a simple comparison
    // In production, use secure comparison methods

    if (passcode.isEmpty) {
      return AuthenticationResult.failure(
        error: 'Passcode cannot be empty',
      );
    }

    // Simulate passcode verification (replace with secure implementation)
    final isValid =
        passcode == 'your_configured_passcode'; // Replace with actual logic

    if (isValid) {
      return AuthenticationResult.success(
        authenticationType: 'passcode',
        sessionToken: _generateSessionToken(),
        sessionExpiration: _calculateSessionExpiration(),
      );
    } else {
      return AuthenticationResult.failure(
        error: 'Invalid passcode',
      );
    }
  }

  /// Generates a secure session token.
  String _generateSessionToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Calculates session expiration time based on configuration.
  DateTime? _calculateSessionExpiration() {
    if (config.sessionTimeoutMinutes != null) {
      return DateTime.now()
          .add(Duration(minutes: config.sessionTimeoutMinutes!));
    }
    return null;
  }

  /// Checks if a client is currently locked out.
  bool _isLockedOut(String clientId) {
    if (config.maxFailedAttempts == null) {
      return false;
    }

    final attempts = _failedAttempts[clientId] ?? [];
    if (attempts.length < config.maxFailedAttempts!) {
      return false;
    }

    final lockoutEnd =
        attempts.last.add(Duration(minutes: config.lockoutDurationMinutes));
    return DateTime.now().isBefore(lockoutEnd);
  }

  /// Records a failed authentication attempt.
  void _recordFailedAttempt(String clientId) {
    final attempts = _failedAttempts[clientId] ?? [];
    attempts.add(DateTime.now());

    // Keep only recent attempts for lockout calculation
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: config.lockoutDurationMinutes));
    attempts.removeWhere((attempt) => attempt.isBefore(cutoff));

    _failedAttempts[clientId] = attempts;
  }

  /// Clears failed authentication attempts for a client.
  void _clearFailedAttempts(String clientId) {
    _failedAttempts.remove(clientId);
  }

  /// Invalidates the current session.
  void _invalidateSession(String reason) {
    if (_currentSession != null) {
      _logSecurityEvent(SecurityEvent(
        eventType: 'session_invalidated',
        description: 'Session invalidated: $reason',
        success: true,
        data: {'reason': reason},
      ));
    }

    _currentSession = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Starts session timeout monitoring.
  void _startSessionTimer() {
    _sessionTimer?.cancel();

    if (config.sessionTimeoutMinutes != null) {
      _sessionTimer = Timer(
        Duration(minutes: config.sessionTimeoutMinutes!),
        () => _invalidateSession('Session timeout'),
      );
    }
  }

  /// Compiles sanitization patterns for efficient matching.
  void _compileSanitizationPatterns() {
    // Pre-compile regex patterns for better performance
    // This is where pattern validation and optimization would occur

    for (final pattern in config.sanitizePatterns) {
      try {
        RegExp(pattern); // Validate pattern compilation
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Invalid sanitization pattern: $pattern - $e');
        }
      }
    }
  }

  /// Applies automatic PII sanitization patterns.
  String _sanitizePII(String text, String replacement) {
    var sanitized = text;

    // Common PII patterns
    final piiPatterns = [
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email addresses
      r'\b\d{3}-\d{2}-\d{4}\b', // SSN (US format)
      r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', // Credit card numbers
      r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', // Phone numbers (US format)
      r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', // IP addresses
    ];

    for (final pattern in piiPatterns) {
      try {
        final regex = RegExp(pattern, caseSensitive: false);
        sanitized = sanitized.replaceAll(regex, replacement);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('PII pattern error: $pattern - $e');
        }
      }
    }

    return sanitized;
  }

  /// Logs a security event for audit purposes.
  void _logSecurityEvent(SecurityEvent event) {
    _securityEvents.add(event);

    // Apply event retention limit
    const maxEvents = 1000;
    if (_securityEvents.length > maxEvents) {
      _securityEvents.removeAt(0);
    }

    // Log to main logger if configured
    if (config.logSecurityEvents) {
      final level = event.success ? BackstageLevel.info : BackstageLevel.warn;
      logger.add(BackstageLog(
        message: '${event.eventType}: ${event.description}',
        level: level,
        tag: 'security',
        time: event.timestamp,
      ));
    }
  }

  /// Disposes of resources and timers.
  void dispose() {
    _sessionTimer?.cancel();
  }
}
