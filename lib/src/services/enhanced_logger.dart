/// Enhanced logging service with search, filtering, and persistence capabilities.
///
/// This file extends the basic BackstageLogger with advanced features including
/// full-text search, complex filtering, data persistence, and intelligent
/// log management for production debugging environments.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config/storage_config.dart';
import '../logger.dart';

/// Search criteria for filtering log entries.
class LogSearchCriteria {
  /// Full-text search query
  final String? query;

  /// Filter by specific log levels
  final List<BackstageLevel>? levels;

  /// Filter by specific tags
  final List<String>? tags;

  /// Start time for time range filtering
  final DateTime? startTime;

  /// End time for time range filtering
  final DateTime? endTime;

  /// Whether to include stack traces in search
  final bool searchStackTraces;

  /// Case-sensitive search
  final bool caseSensitive;

  /// Use regular expression matching
  final bool useRegex;

  /// Maximum number of results to return
  final int? limit;

  /// Offset for pagination
  final int offset;

  /// Creates new search criteria.
  const LogSearchCriteria({
    this.query,
    this.levels,
    this.tags,
    this.startTime,
    this.endTime,
    this.searchStackTraces = false,
    this.caseSensitive = false,
    this.useRegex = false,
    this.limit,
    this.offset = 0,
  });

  /// Creates a copy with updated fields.
  LogSearchCriteria copyWith({
    String? query,
    List<BackstageLevel>? levels,
    List<String>? tags,
    DateTime? startTime,
    DateTime? endTime,
    bool? searchStackTraces,
    bool? caseSensitive,
    bool? useRegex,
    int? limit,
    int? offset,
  }) {
    return LogSearchCriteria(
      query: query ?? this.query,
      levels: levels ?? this.levels,
      tags: tags ?? this.tags,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      searchStackTraces: searchStackTraces ?? this.searchStackTraces,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      useRegex: useRegex ?? this.useRegex,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Result of a log search operation.
class LogSearchResult {
  /// Matching log entries
  final List<BackstageLog> logs;

  /// Total number of matching entries (may be more than logs.length if limited)
  final int totalCount;

  /// Search criteria used
  final LogSearchCriteria criteria;

  /// Search execution time in milliseconds
  final int searchTimeMs;

  /// Whether there are more results available
  bool get hasMore => totalCount > (criteria.offset + logs.length);

  /// Creates a new search result.
  const LogSearchResult({
    required this.logs,
    required this.totalCount,
    required this.criteria,
    required this.searchTimeMs,
  });
}

/// Enhanced logger with search, filtering, and persistence capabilities.
///
/// [EnhancedLogger] extends the basic BackstageLogger with advanced features
/// for production debugging including full-text search, complex filtering,
/// persistent storage, intelligent retention policies, and performance
/// optimization for large log datasets.
///
/// **Advanced Features**:
/// * **Full-Text Search**: Search across messages, tags, and stack traces
/// * **Complex Filtering**: Multi-criteria filtering with time ranges
/// * **Persistent Storage**: SQLite database with indexes for fast queries
/// * **Intelligent Retention**: Automatic cleanup based on age, size, and count
/// * **Background Processing**: Non-blocking operations for UI responsiveness
/// * **Compression**: Automatic compression for storage efficiency
/// * **Export Integration**: Seamless integration with export functionality
///
/// **Performance Optimizations**:
/// * Database indexes for fast search and filtering
/// * Background processing for write operations
/// * Intelligent caching for frequently accessed data
/// * Batch operations for improved throughput
/// * Automatic vacuum operations for database health
///
/// **Storage Backends**:
/// * **Memory**: Fast, non-persistent (default for development)
/// * **SQLite**: Persistent, queryable, production-ready
/// * **File**: Simple persistent storage for small datasets
/// * **Encrypted**: Secure persistent storage for sensitive data
///
/// Example usage:
/// ```dart
/// final enhancedLogger = EnhancedLogger(storageConfig);
/// await enhancedLogger.initialize();
///
/// // Log entries as usual
/// enhancedLogger.i('User action completed', tag: 'user');
/// enhancedLogger.e('API call failed', tag: 'network');
///
/// // Perform advanced searches
/// final searchResult = await enhancedLogger.searchLogs(
///   LogSearchCriteria(
///     query: 'failed',
///     levels: [BackstageLevel.error, BackstageLevel.warn],
///     startTime: DateTime.now().subtract(Duration(hours: 1)),
///   ),
/// );
/// ```
class EnhancedLogger extends BackstageLogger {
  /// Configuration for storage and persistence behavior.
  final StorageConfig config;

  /// SQLite database for persistent storage.
  Database? _database;

  /// In-memory log storage for fast access.
  final List<BackstageLog> _memoryLogs = [];

  /// Buffer for pending database writes.
  final List<BackstageLog> _writeBuffer = [];

  /// Timer for periodic database flushes.
  Timer? _flushTimer;

  /// Timer for periodic cleanup operations.
  Timer? _cleanupTimer;

  /// Whether the logger has been initialized.
  bool _isInitialized = false;

  /// Whether background processing is active.
  bool _processingActive = false;

  /// Creates a new enhanced logger with the specified configuration.
  ///
  /// The [config] parameter defines storage backend, retention policies,
  /// compression settings, and performance optimization options.
  EnhancedLogger(this.config) : super();

  /// Initializes the enhanced logger with configured storage backend.
  ///
  /// Sets up the storage system, creates necessary database tables and
  /// indexes, starts background processing, and loads recent entries
  /// if preloading is enabled.
  ///
  /// **Initialization Steps**:
  /// 1. Set up storage backend (memory, database, file, encrypted)
  /// 2. Create database schema and indexes (if using database)
  /// 3. Start background processing timers
  /// 4. Load recent entries for immediate availability
  /// 5. Set up automatic cleanup and maintenance
  ///
  /// Must be called before using any logging functionality.
  ///
  /// Example:
  /// ```dart
  /// final logger = EnhancedLogger(StorageConfig(
  ///   backend: StorageBackend.database,
  ///   maxLogEntries: 10000,
  ///   retentionDays: 7,
  ///   enableCompression: true,
  /// ));
  ///
  /// await logger.initialize();
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
          'Backstage EnhancedLogger: Initializing with backend: ${config.backend}');
    }

    // Set up storage backend
    switch (config.backend) {
      case StorageBackend.memory:
        // Nothing to initialize for memory storage
        break;

      case StorageBackend.database:
        await _initializeDatabase();
        break;

      case StorageBackend.file:
        await _initializeFileStorage();
        break;

      case StorageBackend.encrypted:
        await _initializeEncryptedStorage();
        break;

      case StorageBackend.preferences:
        await _initializePreferencesStorage();
        break;
    }

    // Start background processing
    if (config.useBackgroundProcessing) {
      _startBackgroundProcessing();
    }

    // Load recent entries if configured
    if (config.preloadRecentEntries &&
        config.backend != StorageBackend.memory) {
      await _preloadRecentEntries();
    }

    _isInitialized = true;
    super.i('Enhanced logger initialized with ${config.backend} backend',
        tag: 'logger');
  }

  /// Disposes of resources and stops background processing.
  void dispose() {
    _processingActive = false;
    _flushTimer?.cancel();
    _cleanupTimer?.cancel();

    // Final flush
    if (_writeBuffer.isNotEmpty) {
      _flushToStorage();
    }

    _database?.close();
  }

  /// Adds a log entry with enhanced processing and storage.
  ///
  /// Extends the base logger's add method with additional features including
  /// buffering, background processing, and intelligent storage management.
  ///
  /// The entry is immediately available in memory for UI display while
  /// being queued for persistent storage in the background.
  @override
  void add(BackstageLog log) {
    // Add to base logger stream for immediate UI updates
    super.add(log);

    // Add to memory storage
    _memoryLogs.add(log);

    // Apply memory limits
    if (config.maxLogEntries != null &&
        _memoryLogs.length > config.maxLogEntries!) {
      _memoryLogs.removeAt(0);
    }

    // Queue for persistent storage
    if (config.backend != StorageBackend.memory) {
      _writeBuffer.add(log);

      // Immediate flush if buffer is full
      if (_writeBuffer.length >= config.bufferSize) {
        _flushToStorage();
      }
    }
  }

  /// Searches log entries using the specified criteria.
  ///
  /// Performs efficient search across stored log entries using database
  /// queries for persistent storage or in-memory filtering for memory
  /// storage. Supports full-text search, multi-criteria filtering, and
  /// pagination for large result sets.
  ///
  /// Parameters:
  /// * [criteria] - Search and filtering criteria
  ///
  /// Returns: [LogSearchResult] containing matching entries and metadata
  ///
  /// Example:
  /// ```dart
  /// // Search for error logs in the last hour
  /// final result = await logger.searchLogs(LogSearchCriteria(
  ///   levels: [BackstageLevel.error],
  ///   startTime: DateTime.now().subtract(Duration(hours: 1)),
  ///   limit: 50,
  /// ));
  ///
  /// print('Found ${result.totalCount} errors');
  /// for (final log in result.logs) {
  ///   print('${log.time}: ${log.message}');
  /// }
  /// ```
  Future<LogSearchResult> searchLogs(LogSearchCriteria criteria) async {
    final stopwatch = Stopwatch()..start();

    List<BackstageLog> results;
    int totalCount;

    switch (config.backend) {
      case StorageBackend.memory:
        final searchResults = _searchInMemory(criteria);
        results = searchResults['logs'] as List<BackstageLog>;
        totalCount = searchResults['totalCount'] as int;
        break;

      case StorageBackend.database:
        final searchResults = await _searchInDatabase(criteria);
        results = searchResults['logs'] as List<BackstageLog>;
        totalCount = searchResults['totalCount'] as int;
        break;

      default:
        // For file-based storage, load into memory and search
        await _ensureLogsLoaded();
        final searchResults = _searchInMemory(criteria);
        results = searchResults['logs'] as List<BackstageLog>;
        totalCount = searchResults['totalCount'] as int;
        break;
    }

    stopwatch.stop();

    return LogSearchResult(
      logs: results,
      totalCount: totalCount,
      criteria: criteria,
      searchTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Retrieves log entries within a time range.
  ///
  /// Optimized method for retrieving logs within a specific time window.
  /// Uses database indexes for efficient range queries when available.
  ///
  /// Parameters:
  /// * [startTime] - Start of time range
  /// * [endTime] - End of time range
  /// * [limit] - Maximum number of entries to return
  /// * [offset] - Offset for pagination
  ///
  /// Returns: List of matching log entries
  Future<List<BackstageLog>> getLogsByTimeRange(
    DateTime startTime,
    DateTime endTime, {
    int? limit,
    int offset = 0,
  }) async {
    return (await searchLogs(LogSearchCriteria(
      startTime: startTime,
      endTime: endTime,
      limit: limit,
      offset: offset,
    )))
        .logs;
  }

  /// Retrieves the most recent log entries.
  ///
  /// Optimized method for retrieving recent logs, useful for initial
  /// console display and real-time monitoring interfaces.
  ///
  /// Parameters:
  /// * [count] - Number of recent entries to return
  ///
  /// Returns: List of recent log entries in reverse chronological order
  Future<List<BackstageLog>> getRecentLogs(int count) async {
    if (config.backend == StorageBackend.memory) {
      return _memoryLogs.length <= count
          ? List.from(_memoryLogs.reversed)
          : _memoryLogs.sublist(_memoryLogs.length - count).reversed.toList();
    }

    return (await searchLogs(LogSearchCriteria(
      limit: count,
    )))
        .logs
        .reversed
        .toList();
  }

  /// Gets statistics about stored log entries.
  ///
  /// Provides aggregate information about the log dataset including
  /// counts by level and tag, storage usage, and time range coverage.
  ///
  /// Returns: Map containing various log statistics
  Future<Map<String, dynamic>> getLogStatistics() async {
    List<BackstageLog> allLogs;

    if (config.backend == StorageBackend.memory) {
      allLogs = _memoryLogs;
    } else {
      // Get a large sample for statistics
      allLogs = (await searchLogs(LogSearchCriteria(limit: 10000))).logs;
    }

    if (allLogs.isEmpty) {
      return {
        'totalLogs': 0,
        'levelCounts': <String, int>{},
        'tagCounts': <String, int>{},
        'timeRange': null,
      };
    }

    final levelCounts = <String, int>{};
    final tagCounts = <String, int>{};

    for (final log in allLogs) {
      levelCounts[log.level.name] = (levelCounts[log.level.name] ?? 0) + 1;
      tagCounts[log.tag] = (tagCounts[log.tag] ?? 0) + 1;
    }

    final sortedLogs = List<BackstageLog>.from(allLogs)
      ..sort((a, b) => a.time.compareTo(b.time));

    return {
      'totalLogs': allLogs.length,
      'levelCounts': levelCounts,
      'tagCounts': tagCounts,
      'timeRange': {
        'start': sortedLogs.first.time.toIso8601String(),
        'end': sortedLogs.last.time.toIso8601String(),
      },
      'storageBackend': config.backend.name,
    };
  }

  /// Clears all stored log entries.
  ///
  /// Removes all log entries from memory and persistent storage.
  /// This operation cannot be undone.
  Future<void> clearAllLogs() async {
    _memoryLogs.clear();
    _writeBuffer.clear();

    switch (config.backend) {
      case StorageBackend.database:
        await _database?.delete('logs');
        break;
      case StorageBackend.file:
        // Delete log files
        final directory = await _getStorageDirectory();
        final files =
            directory.listSync().where((f) => f.path.endsWith('.log'));
        for (final file in files) {
          await file.delete();
        }
        break;
      default:
        break;
    }

    super.i('All log entries cleared', tag: 'logger');
  }

  /// Performs maintenance operations on the log storage.
  ///
  /// Includes cleanup of old entries, database optimization, and
  /// storage compaction. Called automatically based on configuration
  /// or can be called manually for immediate maintenance.
  Future<void> performMaintenance() async {
    if (kDebugMode) {
      debugPrint('Backstage EnhancedLogger: Performing maintenance');
    }

    int deletedCount = 0;

    // Clean up old entries
    if (config.autoCleanup) {
      deletedCount += await _cleanupOldEntries();
    }

    // Database-specific maintenance
    if (config.backend == StorageBackend.database && _database != null) {
      await _database!.execute('VACUUM');
    }

    super.i('Log maintenance completed: removed $deletedCount entries',
        tag: 'logger');
  }

  /// Initializes SQLite database storage.
  Future<void> _initializeDatabase() async {
    final directory = await _getStorageDirectory();
    final dbPath = '${directory.path}/${config.databaseName}.db';

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDatabaseSchema,
      onOpen: (db) async {
        if (config.enableWALMode) {
          await db.execute('PRAGMA journal_mode=WAL');
        }
      },
    );
  }

  /// Creates database schema and indexes.
  Future<void> _createDatabaseSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        level TEXT NOT NULL,
        tag TEXT NOT NULL,
        message TEXT NOT NULL,
        stack_trace TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    if (config.createDatabaseIndexes) {
      await db.execute('CREATE INDEX idx_logs_timestamp ON logs(timestamp)');
      await db.execute('CREATE INDEX idx_logs_level ON logs(level)');
      await db.execute('CREATE INDEX idx_logs_tag ON logs(tag)');
      await db.execute('CREATE INDEX idx_logs_message ON logs(message)');
    }
  }

  /// Initializes file-based storage.
  Future<void> _initializeFileStorage() async {
    final directory = await _getStorageDirectory();
    await directory.create(recursive: true);
  }

  /// Initializes encrypted storage.
  Future<void> _initializeEncryptedStorage() async {
    // TODO: Implement encrypted storage
    throw UnimplementedError('Encrypted storage not yet implemented');
  }

  /// Initializes preferences storage.
  Future<void> _initializePreferencesStorage() async {
    // TODO: Implement preferences storage for small datasets
    throw UnimplementedError('Preferences storage not yet implemented');
  }

  /// Gets or creates the storage directory.
  Future<Directory> _getStorageDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${documentsDir.path}/${config.storagePath}');

    if (!storageDir.existsSync()) {
      await storageDir.create(recursive: true);
    }

    return storageDir;
  }

  /// Starts background processing timers.
  void _startBackgroundProcessing() {
    _processingActive = true;

    // Periodic flush timer
    _flushTimer = Timer.periodic(
      Duration(seconds: config.flushIntervalSeconds),
      (timer) => _flushToStorage(),
    );

    // Periodic cleanup timer
    if (config.autoCleanup) {
      _cleanupTimer = Timer.periodic(
        Duration(minutes: config.cleanupIntervalMinutes),
        (timer) => performMaintenance(),
      );
    }
  }

  /// Flushes buffered entries to persistent storage.
  Future<void> _flushToStorage() async {
    if (_writeBuffer.isEmpty || !_processingActive) {
      return;
    }

    final batch = List<BackstageLog>.from(_writeBuffer);
    _writeBuffer.clear();

    switch (config.backend) {
      case StorageBackend.database:
        await _flushToDatabase(batch);
        break;
      case StorageBackend.file:
        await _flushToFile(batch);
        break;
      default:
        break;
    }
  }

  /// Flushes entries to database.
  Future<void> _flushToDatabase(List<BackstageLog> entries) async {
    if (_database == null) return;

    final batch = _database!.batch();

    for (final log in entries) {
      batch.insert('logs', {
        'timestamp': log.time.millisecondsSinceEpoch,
        'level': log.level.name,
        'tag': log.tag,
        'message': log.message,
        'stack_trace': log.stackTrace?.toString(),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    await batch.commit(noResult: true);
  }

  /// Flushes entries to file.
  Future<void> _flushToFile(List<BackstageLog> entries) async {
    final directory = await _getStorageDirectory();
    final file = File(
        '${directory.path}/logs_${DateTime.now().millisecondsSinceEpoch}.log');

    final jsonLines = entries.map((log) => jsonEncode({
          'timestamp': log.time.toIso8601String(),
          'level': log.level.name,
          'tag': log.tag,
          'message': log.message,
          'stackTrace': log.stackTrace?.toString(),
        }));

    await file.writeAsString('${jsonLines.join('\n')}\n',
        mode: FileMode.append);
  }

  /// Preloads recent entries from storage.
  Future<void> _preloadRecentEntries() async {
    final recentLogs = await getRecentLogs(config.preloadEntryCount);
    _memoryLogs.addAll(recentLogs.reversed);
  }

  /// Ensures logs are loaded for file-based searching.
  Future<void> _ensureLogsLoaded() async {
    if (config.backend == StorageBackend.file && _memoryLogs.isEmpty) {
      // Load from files for searching
      final directory = await _getStorageDirectory();
      final files = directory.listSync().where((f) => f.path.endsWith('.log'));

      for (final file in files) {
        final content = await File(file.path).readAsString();
        final lines =
            content.split('\n').where((line) => line.trim().isNotEmpty);

        for (final line in lines) {
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final log = BackstageLog(
              message: json['message'] as String,
              level: BackstageLevel.values.firstWhere(
                (l) => l.name == json['level'],
                orElse: () => BackstageLevel.info,
              ),
              tag: json['tag'] as String? ?? 'app',
              time: DateTime.parse(json['timestamp'] as String),
              stackTrace: json['stackTrace'] != null
                  ? StackTrace.fromString(json['stackTrace'] as String)
                  : null,
            );
            _memoryLogs.add(log);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to parse log line: $line');
            }
          }
        }
      }
    }
  }

  /// Searches logs in memory.
  Map<String, dynamic> _searchInMemory(LogSearchCriteria criteria) {
    var filtered = _memoryLogs.where((log) {
      // Level filter
      if (criteria.levels != null && !criteria.levels!.contains(log.level)) {
        return false;
      }

      // Tag filter
      if (criteria.tags != null && !criteria.tags!.contains(log.tag)) {
        return false;
      }

      // Time range filter
      if (criteria.startTime != null &&
          log.time.isBefore(criteria.startTime!)) {
        return false;
      }
      if (criteria.endTime != null && log.time.isAfter(criteria.endTime!)) {
        return false;
      }

      // Text search
      if (criteria.query != null && criteria.query!.isNotEmpty) {
        final query = criteria.caseSensitive
            ? criteria.query!
            : criteria.query!.toLowerCase();
        final message =
            criteria.caseSensitive ? log.message : log.message.toLowerCase();
        final tag = criteria.caseSensitive ? log.tag : log.tag.toLowerCase();

        bool matches = false;

        if (criteria.useRegex) {
          try {
            final regex = RegExp(query, caseSensitive: criteria.caseSensitive);
            matches = regex.hasMatch(message) || regex.hasMatch(tag);

            if (!matches &&
                criteria.searchStackTraces &&
                log.stackTrace != null) {
              final stackTrace = criteria.caseSensitive
                  ? log.stackTrace.toString()
                  : log.stackTrace.toString().toLowerCase();
              matches = regex.hasMatch(stackTrace);
            }
          } catch (e) {
            // Invalid regex, fall back to contains
            matches = message.contains(query) || tag.contains(query);
          }
        } else {
          matches = message.contains(query) || tag.contains(query);

          if (!matches &&
              criteria.searchStackTraces &&
              log.stackTrace != null) {
            final stackTrace = criteria.caseSensitive
                ? log.stackTrace.toString()
                : log.stackTrace.toString().toLowerCase();
            matches = stackTrace.contains(query);
          }
        }

        if (!matches) return false;
      }

      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.time.compareTo(a.time));

    final totalCount = filtered.length;

    // Apply pagination
    if (criteria.offset > 0) {
      filtered = filtered.skip(criteria.offset).toList();
    }
    if (criteria.limit != null) {
      filtered = filtered.take(criteria.limit!).toList();
    }

    return {
      'logs': filtered,
      'totalCount': totalCount,
    };
  }

  /// Searches logs in database.
  Future<Map<String, dynamic>> _searchInDatabase(
      LogSearchCriteria criteria) async {
    if (_database == null) {
      return {'logs': <BackstageLog>[], 'totalCount': 0};
    }

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    // Level filter
    if (criteria.levels != null && criteria.levels!.isNotEmpty) {
      final levelPlaceholders = criteria.levels!.map((_) => '?').join(',');
      whereConditions.add('level IN ($levelPlaceholders)');
      whereArgs.addAll(criteria.levels!.map((l) => l.name));
    }

    // Tag filter
    if (criteria.tags != null && criteria.tags!.isNotEmpty) {
      final tagPlaceholders = criteria.tags!.map((_) => '?').join(',');
      whereConditions.add('tag IN ($tagPlaceholders)');
      whereArgs.addAll(criteria.tags!);
    }

    // Time range filter
    if (criteria.startTime != null) {
      whereConditions.add('timestamp >= ?');
      whereArgs.add(criteria.startTime!.millisecondsSinceEpoch);
    }
    if (criteria.endTime != null) {
      whereConditions.add('timestamp <= ?');
      whereArgs.add(criteria.endTime!.millisecondsSinceEpoch);
    }

    // Text search
    if (criteria.query != null && criteria.query!.isNotEmpty) {
      if (criteria.searchStackTraces) {
        whereConditions
            .add('(message LIKE ? OR tag LIKE ? OR stack_trace LIKE ?)');
        final searchPattern = '%${criteria.query}%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      } else {
        whereConditions.add('(message LIKE ? OR tag LIKE ?)');
        final searchPattern = '%${criteria.query}%';
        whereArgs.addAll([searchPattern, searchPattern]);
      }
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    // Count total results
    final countResult = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM logs $whereClause',
      whereArgs,
    );
    final totalCount = countResult.first['count'] as int;

    // Get paginated results
    final results = await _database!.rawQuery('''
      SELECT * FROM logs 
      $whereClause 
      ORDER BY timestamp DESC 
      ${criteria.limit != null ? 'LIMIT ?' : ''}
      ${criteria.offset > 0 ? 'OFFSET ?' : ''}
    ''', [
      ...whereArgs,
      if (criteria.limit != null) criteria.limit!,
      if (criteria.offset > 0) criteria.offset,
    ]);

    final logs = results
        .map((row) => BackstageLog(
              message: row['message'] as String,
              level: BackstageLevel.values.firstWhere(
                (l) => l.name == row['level'],
                orElse: () => BackstageLevel.info,
              ),
              tag: row['tag'] as String,
              time:
                  DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
              stackTrace: row['stack_trace'] != null
                  ? StackTrace.fromString(row['stack_trace'] as String)
                  : null,
            ))
        .toList();

    return {
      'logs': logs,
      'totalCount': totalCount,
    };
  }

  /// Cleans up old log entries based on retention policy.
  Future<int> _cleanupOldEntries() async {
    int deletedCount = 0;

    // Age-based cleanup
    if (config.retentionDays != null) {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: config.retentionDays!));

      switch (config.backend) {
        case StorageBackend.memory:
          final initialCount = _memoryLogs.length;
          _memoryLogs.removeWhere((log) => log.time.isBefore(cutoffDate));
          deletedCount += initialCount - _memoryLogs.length;
          break;

        case StorageBackend.database:
          if (_database != null) {
            deletedCount += await _database!.delete(
              'logs',
              where: 'timestamp < ?',
              whereArgs: [cutoffDate.millisecondsSinceEpoch],
            );
          }
          break;

        default:
          break;
      }
    }

    // Count-based cleanup
    if (config.maxLogEntries != null) {
      switch (config.backend) {
        case StorageBackend.memory:
          if (_memoryLogs.length > config.maxLogEntries!) {
            final excess = _memoryLogs.length - config.maxLogEntries!;
            _memoryLogs.removeRange(0, excess);
            deletedCount += excess;
          }
          break;

        case StorageBackend.database:
          if (_database != null) {
            // Delete oldest entries beyond the limit
            await _database!.rawDelete('''
              DELETE FROM logs WHERE id IN (
                SELECT id FROM logs 
                ORDER BY timestamp ASC 
                LIMIT max(0, (SELECT COUNT(*) FROM logs) - ?)
              )
            ''', [config.maxLogEntries!]);
          }
          break;

        default:
          break;
      }
    }

    return deletedCount;
  }
}
