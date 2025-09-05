/// Storage, persistence, and data retention configuration.
///
/// This file defines configuration options for how log data should be stored,
/// persisted across app sessions, and managed over time including retention
/// policies, compression, and cleanup strategies.
library;

/// Storage backend options for persisting log data.
enum StorageBackend {
  /// In-memory storage only (no persistence)
  memory,

  /// Platform-appropriate key-value storage (SharedPreferences, etc.)
  preferences,

  /// Local file storage in app documents directory
  file,

  /// Local SQLite database for structured storage
  database,

  /// Encrypted local storage for sensitive data
  encrypted,
}

/// Configuration options for log storage and persistence.
///
/// [StorageConfig] specifies how log data should be stored, persisted across
/// application sessions, and managed over time. This includes storage backend
/// selection, retention policies, compression settings, and performance
/// optimizations.
///
/// **Storage Backends**:
/// * **Memory**: Fast, no persistence, lost on app restart
/// * **Preferences**: Simple key-value, limited size, cross-platform
/// * **File**: Direct file I/O, flexible, requires file system access
/// * **Database**: Structured storage, queryable, good for large datasets
/// * **Encrypted**: Secure storage for sensitive data, performance overhead
///
/// **Performance Considerations**:
/// * Memory storage is fastest but provides no persistence
/// * Database storage scales better for large datasets
/// * Encrypted storage has additional CPU/battery overhead
/// * Background processing can improve UI responsiveness
///
/// Example configurations:
/// ```dart
/// // Development configuration (comprehensive logging)
/// const devConfig = StorageConfig(
///   backend: StorageBackend.memory, // Fast, no persistence needed
///   maxLogEntries: 10000,
///   enableCompression: false, // Skip compression for speed
/// );
///
/// // Production configuration (persistent, managed storage)
/// const prodConfig = StorageConfig(
///   backend: StorageBackend.encrypted, // Security for sensitive data
///   maxLogEntries: 5000,
///   retentionDays: 3, // Short retention for privacy
///   enableCompression: true,
///   autoCleanup: true,
/// );
/// ```
class StorageConfig {
  /// Storage backend to use for persisting log data.
  ///
  /// Different backends offer different trade-offs between performance,
  /// persistence, security, and platform compatibility. Choose based
  /// on your application's requirements.
  ///
  /// **Default**: `StorageBackend.memory`
  /// **Trade-offs**: Memory is fast but not persistent
  final StorageBackend backend;

  /// Maximum number of log entries to retain in storage.
  ///
  /// When this limit is reached, older entries will be automatically
  /// removed to prevent unlimited storage growth. Set to null for
  /// no limit (not recommended for long-running applications).
  ///
  /// **Default**: `5000`
  /// **Performance**: Prevents unlimited memory/storage consumption
  final int? maxLogEntries;

  /// Maximum storage size in bytes for log data.
  ///
  /// When storage usage exceeds this limit, older entries will be
  /// automatically removed to stay within the size limit. This provides
  /// predictable storage usage regardless of log entry sizes.
  ///
  /// **Default**: `50MB` (52,428,800 bytes)
  /// **Storage**: Predictable storage footprint
  final int maxStorageBytes;

  /// Number of days to retain log entries before automatic cleanup.
  ///
  /// Log entries older than this will be automatically removed if
  /// [autoCleanup] is enabled. This helps comply with data retention
  /// policies and prevents accumulation of stale debugging data.
  ///
  /// **Default**: `null` (no time-based retention)
  /// **Privacy**: Helps comply with data retention policies
  final int? retentionDays;

  /// Whether to automatically clean up old log entries.
  ///
  /// When enabled, log entries exceeding [maxLogEntries], [maxStorageBytes],
  /// or [retentionDays] limits will be automatically removed. This prevents
  /// unlimited storage growth and helps maintain performance.
  ///
  /// **Default**: `true`
  /// **Maintenance**: Prevents storage and performance issues
  final bool autoCleanup;

  /// Interval in minutes between automatic cleanup operations.
  ///
  /// Automatic cleanup will run at this interval to remove old entries
  /// and maintain storage limits. More frequent cleanup provides better
  /// limit enforcement but uses more CPU resources.
  ///
  /// **Default**: `60` (1 hour)
  /// **Performance**: Balance maintenance with resource usage
  final int cleanupIntervalMinutes;

  /// Whether to compress log data to save storage space.
  ///
  /// Compression significantly reduces storage usage for text-based
  /// log data but adds CPU overhead during read/write operations.
  /// Most beneficial for persistent storage backends.
  ///
  /// **Default**: `false`
  /// **Trade-off**: Storage space vs CPU usage
  final bool enableCompression;

  /// Compression level for log data (0-9, higher = more compression).
  ///
  /// Higher compression levels reduce storage usage but increase
  /// CPU overhead. Level 6 typically provides good balance between
  /// compression ratio and performance.
  ///
  /// **Default**: `6` (balanced compression)
  /// **Performance**: Balance compression ratio with CPU usage
  final int compressionLevel;

  /// Whether to use background processing for storage operations.
  ///
  /// When enabled, storage operations (writes, cleanup, compression)
  /// will be performed on background threads to avoid blocking the
  /// UI thread. Recommended for persistent storage backends.
  ///
  /// **Default**: `true`
  /// **Performance**: Prevents UI blocking during storage operations
  final bool useBackgroundProcessing;

  /// Batch size for storage operations to optimize performance.
  ///
  /// Multiple log entries will be batched together for storage
  /// operations to reduce I/O overhead. Larger batches improve
  /// throughput but may increase memory usage and latency.
  ///
  /// **Default**: `100`
  /// **Performance**: Optimize I/O throughput vs latency
  final int batchSize;

  /// Buffer size for pending log entries before forced write.
  ///
  /// Log entries will be buffered in memory before being written
  /// to persistent storage. This improves performance but may result
  /// in data loss if the app crashes before the buffer is flushed.
  ///
  /// **Default**: `1000`
  /// **Performance**: Balance throughput with data durability
  final int bufferSize;

  /// Interval in seconds to flush buffered entries to storage.
  ///
  /// Buffered log entries will be automatically written to storage
  /// at this interval to prevent data loss while maintaining
  /// performance benefits of batching.
  ///
  /// **Default**: `5` (5 seconds)
  /// **Durability**: Balance performance with data loss risk
  final int flushIntervalSeconds;

  /// Whether to encrypt stored log data.
  ///
  /// When enabled, log data will be encrypted before being written
  /// to persistent storage. This provides additional security for
  /// sensitive debugging information but adds CPU overhead.
  ///
  /// **Default**: `false`
  /// **Security**: Additional protection for sensitive data
  final bool encryptStorage;

  /// Encryption key for stored log data (required if encryptStorage is true).
  ///
  /// The encryption key used to encrypt/decrypt stored log data.
  /// Should be securely generated and managed. Consider using
  /// device keystore or secure key derivation functions.
  ///
  /// **Default**: `null`
  /// **Security**: Use strong, securely generated encryption keys
  final String? encryptionKey;

  /// Path for storing log files (relative to app documents directory).
  ///
  /// When using file-based storage backends, log files will be stored
  /// in this subdirectory within the app's documents directory. This
  /// helps organize storage and avoid conflicts with app data.
  ///
  /// **Default**: `'backstage_logs'`
  /// **Organization**: Keep log files organized and separate
  final String storagePath;

  /// Database name for SQLite storage backend.
  ///
  /// When using database storage, this name will be used for the
  /// SQLite database file. The .db extension will be added automatically.
  ///
  /// **Default**: `'backstage_logs'`
  /// **Database**: Identify the log storage database
  final String databaseName;

  /// Whether to create database indexes for better query performance.
  ///
  /// When using database storage, indexes on timestamp, level, and tag
  /// columns will be created to improve query performance. This uses
  /// additional storage space but significantly improves search speed.
  ///
  /// **Default**: `true`
  /// **Performance**: Improve database query performance
  final bool createDatabaseIndexes;

  /// Whether to enable Write-Ahead Logging for SQLite database.
  ///
  /// WAL mode improves database performance and allows concurrent
  /// reads during writes. Recommended for applications with high
  /// log volume or frequent database access.
  ///
  /// **Default**: `true`
  /// **Performance**: Improve database concurrency and performance
  final bool enableWALMode;

  /// Maximum number of entries to load at once for UI display.
  ///
  /// When loading logs from persistent storage, this limits the
  /// number of entries loaded in a single operation to prevent
  /// memory issues and improve UI responsiveness.
  ///
  /// **Default**: `1000`
  /// **Performance**: Balance memory usage with user experience
  final int maxLoadBatchSize;

  /// Whether to preload recent entries on app startup.
  ///
  /// When enabled, the most recent log entries will be automatically
  /// loaded from storage when the app starts, providing immediate
  /// access to recent debugging information.
  ///
  /// **Default**: `true`
  /// **UX**: Immediate access to recent logs
  final bool preloadRecentEntries;

  /// Number of recent entries to preload on app startup.
  ///
  /// This limits the number of entries preloaded to balance between
  /// immediate availability and startup performance. More entries
  /// provide better debugging continuity but slower startup.
  ///
  /// **Default**: `500`
  /// **Performance**: Balance startup time with debugging utility
  final int preloadEntryCount;

  /// Creates a new storage configuration with the specified options.
  ///
  /// All parameters are optional and have balanced defaults that provide
  /// reasonable storage behavior without excessive resource usage. Adjust
  /// based on your specific storage, performance, and security requirements.
  ///
  /// Example:
  /// ```dart
  /// const config = StorageConfig(
  ///   backend: StorageBackend.database, // Structured, queryable storage
  ///   maxLogEntries: 10000,
  ///   retentionDays: 7,
  ///   enableCompression: true,
  ///   useBackgroundProcessing: true,
  ///   autoCleanup: true,
  ///   encryptStorage: kReleaseMode, // Encrypt in release builds
  /// );
  /// ```
  const StorageConfig({
    this.backend = StorageBackend.memory,
    this.maxLogEntries = 5000,
    this.maxStorageBytes = 52428800, // 50MB
    this.retentionDays,
    this.autoCleanup = true,
    this.cleanupIntervalMinutes = 60,
    this.enableCompression = false,
    this.compressionLevel = 6,
    this.useBackgroundProcessing = true,
    this.batchSize = 100,
    this.bufferSize = 1000,
    this.flushIntervalSeconds = 5,
    this.encryptStorage = false,
    this.encryptionKey,
    this.storagePath = 'backstage_logs',
    this.databaseName = 'backstage_logs',
    this.createDatabaseIndexes = true,
    this.enableWALMode = true,
    this.maxLoadBatchSize = 1000,
    this.preloadRecentEntries = true,
    this.preloadEntryCount = 500,
  });
}
