/// Export and sharing functionality configuration.
///
/// This file defines configuration options for exporting log data in various
/// formats, sharing through platform mechanisms, and controlling what data
/// can be exported for security and privacy compliance.
library;

/// Export formats supported by the Backstage console.
enum ExportFormat {
  /// JavaScript Object Notation - structured, machine-readable
  json,

  /// Comma-Separated Values - spreadsheet compatible
  csv,

  /// Plain text - human-readable, simple format
  text,

  /// HyperText Markup Language - web-viewable with formatting
  html,

  /// Portable Document Format - formatted, printable
  pdf,

  /// SQLite database - queryable, relational format
  sqlite,
}

/// Configuration options for log export and sharing functionality.
///
/// [ExportConfig] specifies how log data can be exported from the console,
/// what formats are available, how files should be named and organized,
/// and what security restrictions should be applied to exported data.
///
/// **Security Considerations**:
/// * Exported data may contain sensitive information
/// * Consider restricting formats and destinations in production
/// * Apply data sanitization before export
/// * Control sharing mechanisms to prevent data leakage
///
/// **Performance Considerations**:
/// * Large log datasets can take time to export
/// * Some formats (PDF, HTML) are more processing-intensive
/// * File I/O operations may block the UI thread
/// * Consider background processing for large exports
///
/// Example configurations:
/// ```dart
/// // Development configuration (full export capabilities)
/// const devConfig = ExportConfig(
///   allowedFormats: ExportFormat.values, // All formats
///   allowSharing: true,
///   includeMetadata: true,
///   includeSystemInfo: true,
/// );
///
/// // Production configuration (restricted export)
/// const prodConfig = ExportConfig(
///   allowedFormats: [ExportFormat.json], // JSON only
///   allowSharing: false, // No platform sharing
///   includeMetadata: false,
///   maxEntriesPerExport: 1000, // Limit export size
/// );
/// ```
class ExportConfig {
  /// List of export formats that should be available to users.
  ///
  /// Only formats included in this list will be shown in the export
  /// interface. Restricting formats can improve security by preventing
  /// export in easily readable formats or limiting processing overhead.
  ///
  /// **Default**: `[ExportFormat.json]`
  /// **Security**: Restrict to minimize data exposure risk
  final List<ExportFormat> allowedFormats;

  /// Whether to enable platform sharing functionality.
  ///
  /// When enabled, exported files can be shared through the platform's
  /// native sharing mechanism (email, messaging, cloud storage, etc.).
  /// Disable in production to prevent accidental data sharing.
  ///
  /// **Default**: `true`
  /// **Security**: Consider disabling in production environments
  final bool allowSharing;

  /// Whether to include metadata in exported files.
  ///
  /// Metadata includes export timestamp, app version, device information,
  /// configuration details, and other contextual information that can
  /// help with debugging but may also reveal system details.
  ///
  /// **Default**: `true`
  /// **Privacy**: May reveal system configuration details
  final bool includeMetadata;

  /// Whether to include system information in exports.
  ///
  /// System information includes device model, OS version, available
  /// memory, network status, and other environmental details that
  /// provide debugging context but may reveal sensitive system details.
  ///
  /// **Default**: `false`
  /// **Privacy**: May reveal sensitive device information
  final bool includeSystemInfo;

  /// Whether to include performance metrics in exports.
  ///
  /// When performance monitoring is enabled, performance data points
  /// can be included in exports to provide comprehensive debugging
  /// information including resource usage patterns.
  ///
  /// **Default**: `true`
  /// **Utility**: Valuable for performance analysis
  final bool includePerformanceMetrics;

  /// Whether to include network request data in exports.
  ///
  /// When network logging is enabled, HTTP request/response data
  /// can be included in exports. Be cautious as this may contain
  /// sensitive authentication or business data.
  ///
  /// **Default**: `false`
  /// **Security**: May contain sensitive network data
  final bool includeNetworkData;

  /// Maximum number of log entries to include in a single export.
  ///
  /// Large log datasets can create unwieldy export files and consume
  /// significant processing time. This limit ensures exports remain
  /// manageable and complete in reasonable time.
  ///
  /// **Default**: `10000`
  /// **Performance**: Prevents excessive processing time and file size
  final int maxEntriesPerExport;

  /// Template for export file naming.
  ///
  /// Variables that will be replaced:
  /// * {timestamp} - Export timestamp (ISO 8601)
  /// * {format} - Export format (json, csv, etc.)
  /// * {count} - Number of entries exported
  /// * {app} - Application name
  /// * {version} - Application version
  ///
  /// **Default**: `'backstage_export_{timestamp}.{format}'`
  /// **Customization**: Align with organizational file naming standards
  final String fileNameTemplate;

  /// Directory path for saving export files (relative to app documents).
  ///
  /// Export files will be saved in this subdirectory within the app's
  /// documents directory. This helps organize exports and makes them
  /// easier to locate for sharing or analysis.
  ///
  /// **Default**: `'backstage_exports'`
  /// **Organization**: Keep exports organized and discoverable
  final String exportDirectory;

  /// Whether to automatically clean up old export files.
  ///
  /// When enabled, export files older than [exportRetentionDays] will
  /// be automatically deleted to prevent unlimited storage consumption
  /// and reduce the risk of old sensitive data accumulation.
  ///
  /// **Default**: `true`
  /// **Privacy**: Prevents accumulation of potentially sensitive data
  final bool autoCleanupExports;

  /// Number of days to retain export files before automatic cleanup.
  ///
  /// Export files older than this will be automatically deleted if
  /// [autoCleanupExports] is enabled. Balance between debugging utility
  /// and privacy/storage concerns.
  ///
  /// **Default**: `7` (one week)
  /// **Privacy**: Balance utility with data retention policies
  final int exportRetentionDays;

  /// Whether to compress export files to save space and transfer time.
  ///
  /// Large export files can be compressed to reduce storage usage
  /// and improve sharing performance. Compression is particularly
  /// effective for text-based formats like JSON and CSV.
  ///
  /// **Default**: `true`
  /// **Performance**: Reduces file size and transfer time
  final bool compressExports;

  /// Compression level for export files (0-9, higher = more compression).
  ///
  /// Higher compression levels reduce file size but increase processing
  /// time. Balance based on your performance and storage requirements.
  ///
  /// **Default**: `6` (balanced compression)
  /// **Performance**: Balance between compression ratio and speed
  final int compressionLevel;

  /// Whether to include stack traces in exported error logs.
  ///
  /// Stack traces provide valuable debugging information but can be
  /// verbose and may reveal internal application structure. Consider
  /// security implications before enabling in production exports.
  ///
  /// **Default**: `true`
  /// **Utility**: Essential for debugging but may reveal code structure
  final bool includeStackTraces;

  /// Whether to encrypt sensitive export files.
  ///
  /// When enabled, export files containing potentially sensitive data
  /// will be encrypted with a user-provided password before saving
  /// or sharing. This provides additional protection for sensitive data.
  ///
  /// **Default**: `false`
  /// **Security**: Additional protection for sensitive exports
  final bool encryptSensitiveExports;

  /// List of log tags that should be excluded from exports.
  ///
  /// Logs with these tags will not be included in export files,
  /// allowing sensitive subsystems or internal operations to be
  /// excluded from shared debugging data.
  ///
  /// **Default**: `[]` (include all tags)
  /// **Security**: Exclude sensitive subsystem logs from exports
  final List<String> excludeTags;

  /// List of log levels that should be excluded from exports.
  ///
  /// Logs at these levels will not be included in export files,
  /// allowing debug-level or trace-level logs to be excluded
  /// from production debugging data sharing.
  ///
  /// **Default**: `[]` (include all levels)
  /// **Security**: Control granularity of exported debugging data
  final List<String> excludeLogLevels;

  /// Whether to show export progress for large operations.
  ///
  /// When enabled, a progress indicator will be displayed during
  /// export operations to provide user feedback for long-running
  /// export processes. Recommended for large datasets.
  ///
  /// **Default**: `true`
  /// **UX**: Provides feedback during potentially long operations
  final bool showExportProgress;

  /// Creates a new export configuration with the specified options.
  ///
  /// All parameters are optional and have balanced defaults that provide
  /// useful export functionality while maintaining reasonable security
  /// and performance characteristics.
  ///
  /// Example:
  /// ```dart
  /// const config = ExportConfig(
  ///   allowedFormats: [
  ///     ExportFormat.json,
  ///     ExportFormat.csv,
  ///   ],
  ///   allowSharing: kDebugMode, // Only allow sharing in debug builds
  ///   includeMetadata: true,
  ///   includeSystemInfo: false, // Protect system details
  ///   maxEntriesPerExport: 5000,
  ///   compressExports: true,
  ///   autoCleanupExports: true,
  ///   exportRetentionDays: 3, // Short retention for security
  /// );
  /// ```
  const ExportConfig({
    this.allowedFormats = const [ExportFormat.json],
    this.allowSharing = true,
    this.includeMetadata = true,
    this.includeSystemInfo = false,
    this.includePerformanceMetrics = true,
    this.includeNetworkData = false,
    this.maxEntriesPerExport = 10000,
    this.fileNameTemplate = 'backstage_export_{timestamp}.{format}',
    this.exportDirectory = 'backstage_exports',
    this.autoCleanupExports = true,
    this.exportRetentionDays = 7,
    this.compressExports = true,
    this.compressionLevel = 6,
    this.includeStackTraces = true,
    this.encryptSensitiveExports = false,
    this.excludeTags = const [],
    this.excludeLogLevels = const [],
    this.showExportProgress = true,
  });
}
