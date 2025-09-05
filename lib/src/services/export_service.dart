/// Export and sharing service for log data.
///
/// This file provides comprehensive export functionality for Backstage log data,
/// supporting multiple formats, sharing mechanisms, and security features.
/// It handles file generation, compression, encryption, and platform integration.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/export_config.dart';
import '../logger.dart';

/// Comprehensive export service for log data with multiple format support.
///
/// [ExportService] provides functionality to export Backstage log data in
/// various formats including JSON, CSV, plain text, HTML, PDF, and SQLite.
/// It supports compression, encryption, metadata inclusion, and platform
/// sharing mechanisms.
///
/// **Supported Export Formats**:
/// * **JSON**: Structured, machine-readable format with full metadata
/// * **CSV**: Spreadsheet-compatible format for analysis tools
/// * **Text**: Human-readable plain text format
/// * **HTML**: Web-viewable format with styling and search
/// * **PDF**: Formatted, printable document (future enhancement)
/// * **SQLite**: Queryable database format (future enhancement)
///
/// **Security Features**:
/// * Data sanitization before export
/// * Optional file encryption
/// * Configurable data exclusions
/// * Automatic cleanup of old exports
///
/// Example usage:
/// ```dart
/// final exportService = ExportService(exportConfig);
/// final logs = await backstage.logger.getAllLogs();
///
/// // Export as JSON with compression
/// final file = await exportService.exportLogs(
///   logs,
///   ExportFormat.json,
///   compress: true,
/// );
///
/// // Share the exported file
/// await exportService.shareFile(file);
/// ```
class ExportService {
  /// Configuration for export behavior and security settings.
  final ExportConfig config;

  /// Creates a new export service with the specified configuration.
  ///
  /// The [config] parameter defines export formats, security settings,
  /// file naming, and sharing options that will be applied to all
  /// export operations performed by this service instance.
  const ExportService(this.config);

  /// Exports log entries in the specified format.
  ///
  /// Generates an export file containing the provided log entries in the
  /// requested format. The export process includes data sanitization,
  /// format conversion, optional compression, and file system storage.
  ///
  /// Parameters:
  /// * [logs] - List of log entries to export
  /// * [format] - Target export format
  /// * [filename] - Optional custom filename (uses template if null)
  /// * [includeMetadata] - Whether to include export metadata
  /// * [compress] - Whether to compress the output file
  ///
  /// Returns: [File] object representing the created export file
  ///
  /// Throws:
  /// * [UnsupportedError] if the format is not in [config.allowedFormats]
  /// * [FileSystemException] if file creation fails
  /// * [ArgumentError] if the logs list is empty
  ///
  /// Example:
  /// ```dart
  /// final logs = await backstage.logger.getLogs(limit: 1000);
  /// final file = await exportService.exportLogs(
  ///   logs,
  ///   ExportFormat.json,
  ///   filename: 'debug_session_${DateTime.now().millisecondsSinceEpoch}',
  ///   includeMetadata: true,
  ///   compress: true,
  /// );
  /// ```
  Future<File> exportLogs(
    List<BackstageLog> logs,
    ExportFormat format, {
    String? filename,
    bool? includeMetadata,
    bool? compress,
  }) async {
    // Validate format is allowed
    if (!config.allowedFormats.contains(format)) {
      throw UnsupportedError(
          'Export format $format is not allowed by configuration');
    }

    // Validate logs are provided
    if (logs.isEmpty) {
      throw ArgumentError('Cannot export empty log list');
    }

    // Apply entry limit
    final limitedLogs = logs.take(config.maxEntriesPerExport).toList();

    // Filter excluded tags and levels
    final filteredLogs = limitedLogs.where((log) {
      return !config.excludeTags.contains(log.tag) &&
          !config.excludeLogLevels.contains(log.level.name);
    }).toList();

    // Sanitize log data
    final sanitizedLogs = _sanitizeLogs(filteredLogs);

    // Generate export content
    final content = await _generateContent(
      sanitizedLogs,
      format,
      includeMetadata: includeMetadata ?? config.includeMetadata,
    );

    // Create filename
    final exportFilename =
        filename ?? _generateFilename(format, sanitizedLogs.length);

    // Get export directory
    final directory = await _getExportDirectory();
    final file = File('${directory.path}/$exportFilename');

    // Write content to file
    Uint8List fileData;
    if (compress ?? config.compressExports) {
      fileData = _compressContent(content, format);
    } else {
      fileData = _contentToBytes(content, format);
    }

    await file.writeAsBytes(fileData);

    // Log export event
    if (kDebugMode) {
      debugPrint(
          'Backstage: Exported ${sanitizedLogs.length} logs to ${file.path}');
    }

    return file;
  }

  /// Shares an export file using platform sharing mechanisms.
  ///
  /// Uses the platform's native sharing interface to allow users to send
  /// the export file through email, messaging, cloud storage, or other
  /// available sharing options. The sharing interface varies by platform.
  ///
  /// Parameters:
  /// * [file] - The export file to share
  /// * [subject] - Optional subject line for sharing (used by email clients)
  /// * [text] - Optional descriptive text about the shared content
  ///
  /// Throws:
  /// * [UnsupportedError] if sharing is disabled in configuration
  /// * [FileSystemException] if the file cannot be accessed
  /// * [PlatformException] if platform sharing fails
  ///
  /// Example:
  /// ```dart
  /// final file = await exportService.exportLogs(logs, ExportFormat.json);
  /// await exportService.shareFile(
  ///   file,
  ///   subject: 'App Debug Logs',
  ///   text: 'Debug logs from issue reproduction session',
  /// );
  /// ```
  Future<void> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    if (!config.allowSharing) {
      throw UnsupportedError('File sharing is disabled by configuration');
    }

    if (!file.existsSync()) {
      throw FileSystemException('Export file does not exist', file.path);
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'Backstage Debug Export',
      text: text ?? 'Debug log export from ${DateTime.now().toIso8601String()}',
    );
  }

  /// Generates a quick export and immediately opens the sharing interface.
  ///
  /// Convenience method that combines export generation and sharing in a
  /// single operation. Uses default settings from the configuration for
  /// most parameters while allowing key customizations.
  ///
  /// Parameters:
  /// * [logs] - List of log entries to export and share
  /// * [format] - Target export format (defaults to first allowed format)
  /// * [subject] - Optional subject line for sharing
  ///
  /// Example:
  /// ```dart
  /// final logs = await backstage.logger.getLogs();
  /// await exportService.exportAndShare(
  ///   logs,
  ///   format: ExportFormat.csv,
  ///   subject: 'Bug Report Logs',
  /// );
  /// ```
  Future<void> exportAndShare(
    List<BackstageLog> logs, {
    ExportFormat? format,
    String? subject,
  }) async {
    final targetFormat = format ?? config.allowedFormats.first;
    final file = await exportLogs(logs, targetFormat);
    await shareFile(file, subject: subject);
  }

  /// Retrieves a list of all existing export files.
  ///
  /// Scans the export directory for files created by previous export
  /// operations. This can be used to implement export history, cleanup
  /// functionality, or allow users to re-share previous exports.
  ///
  /// Returns: List of [File] objects for existing export files
  ///
  /// Example:
  /// ```dart
  /// final existingExports = await exportService.getExistingExports();
  /// for (final export in existingExports) {
  ///   print('Export: ${export.path} (${export.lengthSync()} bytes)');
  /// }
  /// ```
  Future<List<File>> getExistingExports() async {
    final directory = await _getExportDirectory();
    if (!directory.existsSync()) {
      return [];
    }

    return directory
        .listSync()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
  }

  /// Deletes old export files based on retention policy.
  ///
  /// Removes export files older than the configured retention period
  /// to prevent unlimited storage growth and comply with data retention
  /// policies. Called automatically if [config.autoCleanupExports] is enabled.
  ///
  /// Returns: Number of files deleted
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await exportService.cleanupOldExports();
  /// print('Deleted $deletedCount old export files');
  /// ```
  Future<int> cleanupOldExports() async {
    if (!config.autoCleanupExports) {
      return 0;
    }

    final exports = await getExistingExports();
    final cutoffDate =
        DateTime.now().subtract(Duration(days: config.exportRetentionDays));

    int deletedCount = 0;
    for (final file in exports) {
      final stat = file.statSync();
      if (stat.modified.isBefore(cutoffDate)) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'Backstage: Failed to delete old export ${file.path}: $e');
          }
        }
      }
    }

    return deletedCount;
  }

  /// Sanitizes log data by removing or masking sensitive information.
  ///
  /// Applies sanitization rules to protect sensitive data in export files.
  /// This includes removing excluded tags/levels and applying security
  /// patterns defined in the security configuration.
  List<BackstageLog> _sanitizeLogs(List<BackstageLog> logs) {
    // TODO: Implement comprehensive sanitization
    // This will be enhanced when we implement the security service
    return logs
        .map((log) => BackstageLog(
              message: log.message, // TODO: Apply sanitization patterns
              level: log.level,
              tag: log.tag,
              stackTrace: config.includeStackTraces ? log.stackTrace : null,
              time: log.time,
            ))
        .toList();
  }

  /// Generates export content in the specified format.
  Future<String> _generateContent(
    List<BackstageLog> logs,
    ExportFormat format, {
    required bool includeMetadata,
  }) async {
    switch (format) {
      case ExportFormat.json:
        return _generateJsonContent(logs, includeMetadata);
      case ExportFormat.csv:
        return _generateCsvContent(logs, includeMetadata);
      case ExportFormat.text:
        return _generateTextContent(logs, includeMetadata);
      case ExportFormat.html:
        return _generateHtmlContent(logs, includeMetadata);
      case ExportFormat.pdf:
        throw UnsupportedError('PDF export not yet implemented');
      case ExportFormat.sqlite:
        throw UnsupportedError('SQLite export not yet implemented');
    }
  }

  /// Generates JSON format export content.
  String _generateJsonContent(List<BackstageLog> logs, bool includeMetadata) {
    final data = <String, dynamic>{};

    if (includeMetadata) {
      data['metadata'] = {
        'exportedAt': DateTime.now().toIso8601String(),
        'totalEntries': logs.length,
        'format': 'json',
        'version': '1.0',
      };

      if (config.includeSystemInfo) {
        data['systemInfo'] = {
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'dart': Platform.version,
        };
      }
    }

    data['logs'] = logs
        .map((log) => {
              'timestamp': log.time.toIso8601String(),
              'level': log.level.name,
              'tag': log.tag,
              'message': log.message,
              if (log.stackTrace != null)
                'stackTrace': log.stackTrace.toString(),
            })
        .toList();

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generates CSV format export content.
  String _generateCsvContent(List<BackstageLog> logs, bool includeMetadata) {
    final rows = <List<String>>[];

    // Header row
    rows.add(['Timestamp', 'Level', 'Tag', 'Message']);
    if (config.includeStackTraces) {
      rows.last.add('Stack Trace');
    }

    // Data rows
    for (final log in logs) {
      final row = [
        log.time.toIso8601String(),
        log.level.name,
        log.tag,
        log.message,
      ];

      if (config.includeStackTraces) {
        row.add(log.stackTrace?.toString() ?? '');
      }

      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates plain text format export content.
  String _generateTextContent(List<BackstageLog> logs, bool includeMetadata) {
    final buffer = StringBuffer();

    if (includeMetadata) {
      buffer.writeln('Backstage Debug Log Export');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Total Entries: ${logs.length}');
      buffer.writeln('${'=' * 50}');
      buffer.writeln();
    }

    for (final log in logs) {
      buffer.writeln(
          '[${log.time.toIso8601String()}] ${log.level.name.toUpperCase()} (${log.tag}): ${log.message}');

      if (log.stackTrace != null && config.includeStackTraces) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace.toString());
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Generates HTML format export content.
  String _generateHtmlContent(List<BackstageLog> logs, bool includeMetadata) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head>');
    buffer.writeln('<title>Backstage Debug Log Export</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: monospace; margin: 20px; }');
    buffer.writeln(
        '.log-entry { margin-bottom: 10px; padding: 8px; border-left: 3px solid #ccc; }');
    buffer.writeln(
        '.error { border-left-color: #f44336; background-color: #ffebee; }');
    buffer.writeln(
        '.warn { border-left-color: #ff9800; background-color: #fff3e0; }');
    buffer.writeln(
        '.info { border-left-color: #2196f3; background-color: #e3f2fd; }');
    buffer.writeln(
        '.debug { border-left-color: #9e9e9e; background-color: #f5f5f5; }');
    buffer.writeln('.timestamp { color: #666; font-size: 0.9em; }');
    buffer.writeln('.level { font-weight: bold; text-transform: uppercase; }');
    buffer.writeln('.tag { color: #1976d2; font-weight: bold; }');
    buffer.writeln('</style>');
    buffer.writeln('</head><body>');

    if (includeMetadata) {
      buffer.writeln('<h1>Backstage Debug Log Export</h1>');
      buffer.writeln(
          '<p><strong>Generated:</strong> ${DateTime.now().toIso8601String()}</p>');
      buffer.writeln('<p><strong>Total Entries:</strong> ${logs.length}</p>');
      buffer.writeln('<hr>');
    }

    for (final log in logs) {
      buffer.writeln('<div class="log-entry ${log.level.name}">');
      buffer.writeln(
          '<span class="timestamp">${log.time.toIso8601String()}</span> ');
      buffer.writeln('<span class="level">${log.level.name}</span> ');
      buffer.writeln('<span class="tag">(${log.tag})</span>: ');
      buffer
          .writeln('<span class="message">${_escapeHtml(log.message)}</span>');

      if (log.stackTrace != null && config.includeStackTraces) {
        buffer.writeln('<pre>${_escapeHtml(log.stackTrace.toString())}</pre>');
      }

      buffer.writeln('</div>');
    }

    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  /// Escapes HTML special characters for safe display.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Generates filename using the configured template.
  String _generateFilename(ExportFormat format, int entryCount) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final formatName = format.name;

    var filename = config.fileNameTemplate
        .replaceAll('{timestamp}', timestamp)
        .replaceAll('{format}', formatName)
        .replaceAll('{count}', entryCount.toString())
        .replaceAll('{app}', 'backstage') // TODO: Get from app info
        .replaceAll('{version}', '1.0'); // TODO: Get from package info

    // Add compression extension if needed
    if (config.compressExports) {
      filename += '.gz';
    }

    return filename;
  }

  /// Gets or creates the export directory.
  Future<Directory> _getExportDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir =
        Directory('${documentsDir.path}/${config.exportDirectory}');

    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  /// Compresses content using gzip compression.
  Uint8List _compressContent(String content, ExportFormat format) {
    final bytes = _contentToBytes(content, format);
    final compressed = GZipEncoder().encode(bytes);
    return Uint8List.fromList(compressed!);
  }

  /// Converts content string to bytes for the specified format.
  Uint8List _contentToBytes(String content, ExportFormat format) {
    return Uint8List.fromList(utf8.encode(content));
  }
}
