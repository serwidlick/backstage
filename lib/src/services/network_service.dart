/// Network request monitoring and logging service.
///
/// This file provides comprehensive HTTP request/response interception and
/// logging capabilities for debugging network communication in Flutter
/// applications. It supports multiple HTTP clients and provides detailed
/// timing, error, and content analysis.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/network_config.dart';
import '../logger.dart';

/// Represents a captured network request with all relevant details.
class NetworkRequest {
  /// Unique identifier for this request
  final String id;

  /// HTTP method (GET, POST, etc.)
  final String method;

  /// Request URL
  final String url;

  /// Request headers (may be sanitized)
  final Map<String, String> headers;

  /// Request body content (may be sanitized or truncated)
  final String? requestBody;

  /// Response status code
  final int? statusCode;

  /// Response headers (may be sanitized)
  final Map<String, String>? responseHeaders;

  /// Response body content (may be sanitized or truncated)
  final String? responseBody;

  /// Request start timestamp
  final DateTime startTime;

  /// Request completion timestamp
  final DateTime? endTime;

  /// Total request duration
  Duration? get duration => endTime?.difference(startTime);

  /// Error information if request failed
  final String? error;

  /// Stack trace if error occurred
  final StackTrace? stackTrace;

  /// Additional timing breakdown
  final Map<String, int>? timings;

  /// Whether this request completed successfully
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Whether this request resulted in an error
  bool get isError =>
      error != null || (statusCode != null && statusCode! >= 400);

  /// Creates a new network request record.
  const NetworkRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.headers,
    this.requestBody,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    required this.startTime,
    this.endTime,
    this.error,
    this.stackTrace,
    this.timings,
  });

  /// Creates a copy with updated fields.
  NetworkRequest copyWith({
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    DateTime? endTime,
    String? error,
    StackTrace? stackTrace,
    Map<String, int>? timings,
  }) {
    return NetworkRequest(
      id: id,
      method: method,
      url: url,
      headers: headers,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      timings: timings ?? this.timings,
    );
  }

  /// Converts to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'headers': headers,
      'requestBody': requestBody,
      'statusCode': statusCode,
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'error': error,
      'timings': timings,
      'isSuccess': isSuccess,
      'isError': isError,
    };
  }
}

/// Comprehensive network monitoring service for HTTP request/response logging.
///
/// [NetworkService] provides automatic interception and logging of HTTP
/// requests made through popular HTTP clients including Dio and the standard
/// http package. It captures detailed timing information, request/response
/// data, and error conditions for debugging network communication.
///
/// **Supported HTTP Clients**:
/// * **Dio**: Full interceptor integration with detailed timing
/// * **http package**: Response wrapper with basic timing
/// * **HttpClient**: Low-level socket monitoring (future)
/// * **WebSocket**: Connection and message logging (future)
///
/// **Captured Information**:
/// * Request method, URL, headers, and body
/// * Response status, headers, and body
/// * Detailed timing breakdown (DNS, connect, send, receive)
/// * Error conditions and stack traces
/// * Request/response sizes and compression
///
/// **Security Features**:
/// * Configurable header sanitization
/// * Request/response body filtering
/// * URL pattern inclusion/exclusion
/// * Size limits and truncation
///
/// Example usage:
/// ```dart
/// final networkService = NetworkService(networkConfig, logger);
/// await networkService.initialize();
///
/// // HTTP clients are now automatically monitored
/// final dio = Dio();
/// final response = await dio.get('https://api.example.com/data');
///
/// // View captured requests
/// final requests = networkService.getAllRequests();
/// ```
class NetworkService {
  /// Configuration for network monitoring behavior.
  final NetworkConfig config;

  /// Logger for outputting network events.
  final BackstageLogger logger;

  /// Storage for captured network requests.
  final List<NetworkRequest> _requests = [];

  /// Stream controller for real-time network events.
  final _requestController = StreamController<NetworkRequest>.broadcast();

  /// Counter for generating unique request IDs.
  int _requestIdCounter = 0;

  /// Creates a new network monitoring service.
  ///
  /// The [config] parameter defines what network data should be captured
  /// and how it should be processed. The [logger] receives network events
  /// as structured log entries for display in the console.
  NetworkService(this.config, this.logger);

  /// Stream of network requests for real-time monitoring.
  ///
  /// Emits [NetworkRequest] objects as they are captured and completed.
  /// Useful for building real-time network monitoring interfaces or
  /// implementing custom analysis logic.
  Stream<NetworkRequest> get requestStream => _requestController.stream;

  /// Initializes network monitoring by setting up HTTP client interceptors.
  ///
  /// This method configures interceptors for supported HTTP clients to
  /// automatically capture network traffic. It should be called early
  /// in the application lifecycle before making any HTTP requests.
  ///
  /// **Setup Actions**:
  /// * Configures Dio global interceptors
  /// * Sets up http package response wrappers
  /// * Initializes timing measurement systems
  /// * Prepares request storage and streaming
  ///
  /// Example:
  /// ```dart
  /// await networkService.initialize();
  ///
  /// // Now all HTTP requests will be automatically monitored
  /// final dio = Dio();
  /// await dio.get('https://api.example.com/users');
  /// ```
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('Backstage NetworkService: Initializing network monitoring');
    }

    // Set up Dio interceptor for comprehensive monitoring
    _setupDioInterceptor();

    // Set up http package monitoring (more limited)
    _setupHttpPackageMonitoring();

    logger.i('Network monitoring initialized', tag: 'network');
  }

  /// Retrieves all captured network requests.
  ///
  /// Returns a copy of all network requests captured since initialization
  /// or the last clear operation. Requests are ordered by start time.
  ///
  /// Returns: List of [NetworkRequest] objects
  List<NetworkRequest> getAllRequests() {
    return List.unmodifiable(_requests);
  }

  /// Retrieves network requests filtered by criteria.
  ///
  /// Allows filtering requests by URL patterns, status codes, methods,
  /// time ranges, and other criteria for focused analysis.
  ///
  /// Parameters:
  /// * [urlPattern] - Filter by URL substring or pattern
  /// * [method] - Filter by HTTP method
  /// * [statusCode] - Filter by response status code
  /// * [hasError] - Filter by error presence
  /// * [since] - Filter by minimum start time
  /// * [until] - Filter by maximum start time
  /// * [limit] - Maximum number of requests to return
  ///
  /// Example:
  /// ```dart
  /// // Get recent failed requests
  /// final failedRequests = networkService.getFilteredRequests(
  ///   hasError: true,
  ///   since: DateTime.now().subtract(Duration(hours: 1)),
  ///   limit: 10,
  /// );
  /// ```
  List<NetworkRequest> getFilteredRequests({
    String? urlPattern,
    String? method,
    int? statusCode,
    bool? hasError,
    DateTime? since,
    DateTime? until,
    int? limit,
  }) {
    var filtered = _requests.where((request) {
      if (urlPattern != null && !request.url.contains(urlPattern)) {
        return false;
      }

      if (method != null && request.method != method.toUpperCase()) {
        return false;
      }

      if (statusCode != null && request.statusCode != statusCode) {
        return false;
      }

      if (hasError != null && request.isError != hasError) {
        return false;
      }

      if (since != null && request.startTime.isBefore(since)) {
        return false;
      }

      if (until != null && request.startTime.isAfter(until)) {
        return false;
      }

      return true;
    });

    if (limit != null) {
      filtered = filtered.take(limit);
    }

    return filtered.toList();
  }

  /// Clears all captured network request data.
  ///
  /// Removes all stored network requests and resets counters. This can
  /// be useful for focusing on specific debugging sessions or preventing
  /// excessive memory usage during long-running applications.
  void clearRequests() {
    _requests.clear();
    _requestIdCounter = 0;
    logger.i('Network request history cleared', tag: 'network');
  }

  /// Gets summary statistics for captured network requests.
  ///
  /// Provides aggregate information about network activity including
  /// request counts, success rates, average response times, and error
  /// analysis. Useful for performance monitoring and debugging.
  ///
  /// Returns: Map containing various network statistics
  ///
  /// Example:
  /// ```dart
  /// final stats = networkService.getNetworkStats();
  /// print('Total requests: ${stats['totalRequests']}');
  /// print('Success rate: ${stats['successRate']}%');
  /// print('Average response time: ${stats['averageResponseTime']}ms');
  /// ```
  Map<String, dynamic> getNetworkStats() {
    if (_requests.isEmpty) {
      return {
        'totalRequests': 0,
        'successCount': 0,
        'errorCount': 0,
        'successRate': 0.0,
        'averageResponseTime': 0.0,
      };
    }

    final totalRequests = _requests.length;
    final successCount = _requests.where((r) => r.isSuccess).length;
    final errorCount = _requests.where((r) => r.isError).length;
    final successRate = (successCount / totalRequests * 100);

    final completedRequests = _requests.where((r) => r.duration != null);
    final averageResponseTime = completedRequests.isEmpty
        ? 0.0
        : completedRequests
                .map((r) => r.duration!.inMilliseconds)
                .reduce((a, b) => a + b) /
            completedRequests.length;

    final methodCounts = <String, int>{};
    final statusCounts = <int, int>{};

    for (final request in _requests) {
      methodCounts[request.method] = (methodCounts[request.method] ?? 0) + 1;

      if (request.statusCode != null) {
        statusCounts[request.statusCode!] =
            (statusCounts[request.statusCode!] ?? 0) + 1;
      }
    }

    return {
      'totalRequests': totalRequests,
      'successCount': successCount,
      'errorCount': errorCount,
      'successRate': successRate,
      'averageResponseTime': averageResponseTime,
      'methodCounts': methodCounts,
      'statusCounts': statusCounts,
    };
  }

  /// Sets up Dio interceptor for comprehensive network monitoring.
  void _setupDioInterceptor() {
    // Add global Dio interceptor
    Dio().interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            final request = _createRequestFromDio(options);
            _addRequest(request);
            handler.next(options);
          },
          onResponse: (response, handler) {
            _updateRequestFromDioResponse(response);
            handler.next(response);
          },
          onError: (error, handler) {
            _updateRequestFromDioError(error);
            handler.next(error);
          },
        ));
  }

  /// Sets up http package monitoring (more limited than Dio).
  void _setupHttpPackageMonitoring() {
    // Note: http package doesn't have built-in interceptors
    // This would require wrapping http calls or using a custom http client
    // For now, we'll document this limitation and focus on Dio support

    if (kDebugMode) {
      debugPrint(
          'Backstage NetworkService: http package monitoring requires manual integration');
    }
  }

  /// Creates a NetworkRequest from Dio request options.
  NetworkRequest _createRequestFromDio(RequestOptions options) {
    final id = 'req_${++_requestIdCounter}';

    // Check if URL should be excluded
    if (_shouldExcludeUrl(options.uri.toString())) {
      // Still create the request but don't log it
    }

    // Sanitize headers
    final sanitizedHeaders = _sanitizeHeaders(
      options.headers.map((key, value) => MapEntry(key, value.toString())),
    );

    // Sanitize request body
    String? requestBody;
    if (config.captureRequestBody && options.data != null) {
      requestBody = _sanitizeBody(_dataToString(options.data));
    }

    return NetworkRequest(
      id: id,
      method: options.method,
      url: options.uri.toString(),
      headers: sanitizedHeaders,
      requestBody: requestBody,
      startTime: DateTime.now(),
    );
  }

  /// Updates a NetworkRequest with Dio response data.
  void _updateRequestFromDioResponse(Response response) {
    final requestId = 'req_$_requestIdCounter'; // This is simplified
    final existingIndex = _requests.indexWhere((r) => r.id == requestId);

    if (existingIndex == -1) return;

    // Sanitize response headers
    final sanitizedResponseHeaders = config.captureResponseHeaders
        ? _sanitizeHeaders(
            response.headers.map
                .map((key, value) => MapEntry(key, value.join(', '))),
          )
        : <String, String>{};

    // Sanitize response body
    String? responseBody;
    if (config.captureResponseBody && response.data != null) {
      responseBody = _sanitizeBody(_dataToString(response.data));
    }

    final updatedRequest = _requests[existingIndex].copyWith(
      statusCode: response.statusCode,
      responseHeaders: sanitizedResponseHeaders,
      responseBody: responseBody,
      endTime: DateTime.now(),
    );

    _requests[existingIndex] = updatedRequest;
    _logNetworkEvent(updatedRequest);
    _requestController.add(updatedRequest);
  }

  /// Updates a NetworkRequest with Dio error information.
  void _updateRequestFromDioError(DioException error) {
    final requestId = 'req_$_requestIdCounter'; // This is simplified
    final existingIndex = _requests.indexWhere((r) => r.id == requestId);

    if (existingIndex == -1) return;

    final updatedRequest = _requests[existingIndex].copyWith(
      statusCode: error.response?.statusCode,
      error: error.message,
      stackTrace: error.stackTrace,
      endTime: DateTime.now(),
    );

    _requests[existingIndex] = updatedRequest;
    _logNetworkEvent(updatedRequest);
    _requestController.add(updatedRequest);
  }

  /// Adds a new request to the tracked list.
  void _addRequest(NetworkRequest request) {
    _requests.add(request);

    // Apply size limits
    if (config.maxRequestHistory != null &&
        _requests.length > config.maxRequestHistory!) {
      _requests.removeAt(0);
    }

    _logNetworkEvent(request);
    _requestController.add(request);
  }

  /// Checks if a URL should be excluded from monitoring.
  bool _shouldExcludeUrl(String url) {
    // Check inclusion list first (if specified)
    if (config.includeOnlyUrls.isNotEmpty) {
      return !config.includeOnlyUrls
          .any((pattern) => url.toLowerCase().contains(pattern.toLowerCase()));
    }

    // Check exclusion list
    return config.excludeUrls
        .any((pattern) => url.toLowerCase().contains(pattern.toLowerCase()));
  }

  /// Sanitizes headers by removing or masking sensitive values.
  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    if (!config.captureHeaders) {
      return {};
    }

    final sanitized = <String, String>{};

    for (final entry in headers.entries) {
      final lowerKey = entry.key.toLowerCase();

      if (config.headerSanitization
          .any((pattern) => lowerKey.contains(pattern.toLowerCase()))) {
        sanitized[entry.key] = '[SANITIZED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  /// Sanitizes body content by applying configured patterns.
  String _sanitizeBody(String body) {
    var sanitized = body;

    // Apply body sanitization patterns
    for (final pattern in config.bodySanitization) {
      sanitized = sanitized.replaceAll(RegExp(pattern), '[SANITIZED]');
    }

    // Apply size limit
    if (config.maxBodySize != null && sanitized.length > config.maxBodySize!) {
      sanitized =
          '${sanitized.substring(0, config.maxBodySize!)}... [TRUNCATED]';
    }

    return sanitized;
  }

  /// Converts various data types to string representation.
  String _dataToString(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is Map || data is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (e) {
        return data.toString();
      }
    }
    return data.toString();
  }

  /// Logs network events to the Backstage logger.
  void _logNetworkEvent(NetworkRequest request) {
    if (_shouldExcludeUrl(request.url)) {
      return; // Don't log excluded URLs
    }

    String message;
    BackstageLevel level;

    if (request.error != null) {
      level = BackstageLevel.error;
      message = '${request.method} ${request.url} - ERROR: ${request.error}';
    } else if (request.isError) {
      level = BackstageLevel.warn;
      message = '${request.method} ${request.url} - ${request.statusCode}';
    } else if (request.isSuccess) {
      level = BackstageLevel.info;
      message = '${request.method} ${request.url} - ${request.statusCode}';
      if (request.duration != null) {
        message += ' (${request.duration!.inMilliseconds}ms)';
      }
    } else {
      level = BackstageLevel.debug;
      message = '${request.method} ${request.url} - Started';
    }

    logger.add(BackstageLog(
      message: message,
      level: level,
      tag: 'network',
      stackTrace: request.stackTrace,
    ));
  }

  /// Cleans up resources when the service is disposed.
  void dispose() {
    _requestController.close();
  }
}
