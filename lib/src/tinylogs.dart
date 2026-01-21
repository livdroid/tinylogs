import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'config/tinylogs_config.dart';
import 'database/database_helper.dart';
import 'database/log_repository.dart';
import 'models/log_entry.dart';
import 'models/log_level.dart';

/// Main class for managing logs with TinyLogs
class TinyLogs {
  static TinyLogs? _instance;
  LogRepository? _repository;
  late TinyLogsConfig _config;
  bool _initialized = false;

  /// StreamController to notify new logs in real-time
  StreamController<LogEntry>? _logStreamController;

  TinyLogs._();

  /// Gets the singleton instance of TinyLogs
  static TinyLogs get instance {
    _instance ??= TinyLogs._();
    return _instance!;
  }

  /// Injects a custom repository (for testing purposes)
  ///
  /// Must be called before [init]. Allows injecting a mock repository
  /// for unit testing without hitting a real database.
  ///
  /// Example:
  /// ```dart
  /// final mockRepo = MockLogRepository();
  /// TinyLogs.instance.setRepository(mockRepo);
  /// await TinyLogs.instance.init();
  /// ```
  @visibleForTesting
  void setRepository(LogRepository repository) {
    if (_initialized) {
      throw StateError(
        'Cannot set repository after initialization. Call reset() first.',
      );
    }
    _repository = repository;
  }

  /// Stream of new logs (broadcast, multiple listeners supported)
  ///
  /// Usage example:
  /// ```dart
  /// TinyLogs.instance.logStream.listen((log) {
  ///   print('New log: ${log.content}');
  /// });
  /// ```
  Stream<LogEntry> get logStream {
    _ensureInitialized();
    return _logStreamController!.stream;
  }

  /// Internal debug print that respects enableLogs config
  void _debugLog(String message) {
    if (!kReleaseMode && _initialized && _config.enableLogs) {
      debugPrint(message);
    }
  }

  /// Initializes TinyLogs with the configuration
  Future<void> init([TinyLogsConfig? config]) async {
    if (_initialized) {
      _debugLog('TinyLogs: Already initialized');
      return;
    }

    _config = config ?? const TinyLogsConfig();

    // Validate configuration
    if (_config.retentionDuration.inSeconds <= 0) {
      throw ArgumentError('Retention duration must be positive');
    }

    // Use injected repository or create default DatabaseHelper
    _repository ??= DatabaseHelper(databaseName: _config.databaseName);

    // Initialize the stream controller
    _logStreamController = StreamController<LogEntry>.broadcast();

    // Initialize the database (if using DatabaseHelper)
    if (_repository is DatabaseHelper) {
      await (_repository as DatabaseHelper).database;
    }

    _initialized = true;

    // Clean up old logs at startup
    final deletedCount =
        await _repository!.deleteOldLogs(_config.retentionDuration);
    if (deletedCount > 0) {
      _debugLog('TinyLogs: $deletedCount old log(s) deleted at startup');
    }

    _debugLog('TinyLogs: Initialized successfully');
  }

  /// Ensures TinyLogs is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'TinyLogs is not initialized. Call TinyLogs.instance.init() first.',
      );
    }
  }

  // ============================================
  // LOG METHODS BY LEVEL
  // ============================================

  /// Records a log with a specified level
  Future<int> log(String content, {LogLevel level = LogLevel.info}) async {
    _ensureInitialized();

    if (content.isEmpty) {
      throw ArgumentError('Log content cannot be empty');
    }

    final logEntry = LogEntry.now(content, level: level);
    final id = await _repository!.insertLog(logEntry);

    // Notify listeners of the new log
    _logStreamController?.add(logEntry.copyWith(id: id));

    return id;
  }

  /// Records a DEBUG level log
  Future<int> debug(String content) => log(content, level: LogLevel.debug);

  /// Records an INFO level log
  Future<int> info(String content) => log(content, level: LogLevel.info);

  /// Records a WARNING level log
  Future<int> warning(String content) => log(content, level: LogLevel.warning);

  /// Records an ERROR level log
  Future<int> error(String content) => log(content, level: LogLevel.error);

  // ============================================
  // BATCH INSERT
  // ============================================

  /// Records multiple logs in a single transaction
  ///
  /// More performant than individual calls to [log]
  /// Returns the list of generated IDs
  Future<List<int>> logBatch(List<String> contents,
      {LogLevel level = LogLevel.info}) async {
    _ensureInitialized();

    if (contents.isEmpty) return [];

    final entries = contents
        .where((c) => c.isNotEmpty)
        .map((c) => LogEntry.now(c, level: level))
        .toList();

    if (entries.isEmpty) return [];

    final ids = await _repository!.insertLogs(entries);

    // Notify listeners for each log
    for (var i = 0; i < entries.length; i++) {
      _logStreamController?.add(entries[i].copyWith(id: ids[i]));
    }

    return ids;
  }

  // ============================================
  // LOG RETRIEVAL
  // ============================================

  /// Retrieves all logs
  Future<List<LogEntry>> getAllLogs() async {
    _ensureInitialized();
    return await _repository!.getAllLogs();
  }

  /// Retrieves logs with pagination
  ///
  /// [page] Page number (starts at 0)
  /// [pageSize] Number of items per page (default: 50)
  /// [minLevel] Optional filter by minimum level
  Future<PaginatedLogs> getLogsPaginated({
    int page = 0,
    int pageSize = 50,
    LogLevel? minLevel,
  }) async {
    _ensureInitialized();
    return await _repository!.getLogsPaginated(
      page: page,
      pageSize: pageSize,
      minLevel: minLevel,
    );
  }

  /// Retrieves logs within a time range
  Future<List<LogEntry>> getLogsInRange(DateTime start, DateTime end) async {
    _ensureInitialized();

    if (start.isAfter(end)) {
      throw ArgumentError('Start date must be before end date');
    }

    return await _repository!.getLogsInRange(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
  }

  /// Retrieves logs around a specific date (±12h by default)
  ///
  /// [dateTime] The center date
  /// [margin] The margin before and after (default 12 hours)
  Future<List<LogEntry>> getLogsAround(
    DateTime dateTime, {
    Duration margin = const Duration(hours: 12),
  }) async {
    _ensureInitialized();
    return await _repository!.getLogsAround(dateTime, margin: margin);
  }

  /// Retrieves logs by minimum level
  ///
  /// Example: `getLogsByLevel(LogLevel.warning)` returns all
  /// warning and error logs
  Future<List<LogEntry>> getLogsByLevel(LogLevel minLevel) async {
    _ensureInitialized();
    return await _repository!.getLogsByLevel(minLevel);
  }

  // ============================================
  // EXPORT (JSON / CSV) - no third-party lib
  // ============================================

  /// Exports logs to JSON
  ///
  /// Returns a JSON string containing all logs
  Future<String> exportToJson({List<LogEntry>? logs}) async {
    _ensureInitialized();
    final logsToExport = logs ?? await getAllLogs();

    final jsonList = logsToExport.map((log) => {
          'id': log.id,
          'timestamp': log.timestamp,
          'dateTime': log.dateTime.toIso8601String(),
          'level': log.level.name,
          'content': log.content,
        }).toList();

    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Exports logs to CSV
  ///
  /// Returns a CSV string with headers
  Future<String> exportToCsv({List<LogEntry>? logs}) async {
    _ensureInitialized();
    final logsToExport = logs ?? await getAllLogs();

    final buffer = StringBuffer();

    // Headers
    buffer.writeln('id,timestamp,dateTime,level,content');

    // Data
    for (final log in logsToExport) {
      // Escape quotes and commas in content
      final escapedContent = _escapeCsvField(log.content);
      buffer.writeln(
          '${log.id},${log.timestamp},${log.dateTime.toIso8601String()},${log.level.name},$escapedContent');
    }

    return buffer.toString();
  }

  /// Escapes a CSV field according to RFC 4180
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // ============================================
  // MAINTENANCE
  // ============================================

  /// Cleans up logs older than the configured retention duration
  Future<int> cleanupOldLogs() async {
    _ensureInitialized();
    final deletedCount =
        await _repository!.deleteOldLogs(_config.retentionDuration);

    if (deletedCount > 0) {
      _debugLog('TinyLogs: $deletedCount old log(s) deleted');
    }

    return deletedCount;
  }

  /// Counts the total number of logs
  Future<int> getLogCount() async {
    _ensureInitialized();
    return await _repository!.getLogCount();
  }

  /// Deletes all logs (warning: irreversible!)
  Future<int> clearAllLogs() async {
    _ensureInitialized();
    final deletedCount = await _repository!.deleteAllLogs();
    _debugLog('TinyLogs: All logs have been deleted ($deletedCount logs)');
    return deletedCount;
  }

  /// Closes the database and releases resources
  ///
  /// After calling this, you must call [init] again to use TinyLogs.
  Future<void> close() async {
    if (_initialized) {
      // Close the stream controller to prevent memory leaks
      await _logStreamController?.close();
      _logStreamController = null;

      await _repository!.close();
      _initialized = false;

      if (!kReleaseMode && _config.enableLogs) {
        debugPrint('TinyLogs: Database closed');
      }
    }
  }

  /// Completely resets TinyLogs (mainly for testing)
  ///
  /// Closes all resources and clears the singleton instance.
  @visibleForTesting
  Future<void> reset() async {
    final shouldLog = _initialized && !kReleaseMode && _config.enableLogs;

    if (_initialized) {
      // Close the stream controller
      await _logStreamController?.close();
      _logStreamController = null;

      // Delete the database
      if (_repository is DatabaseHelper) {
        await (_repository as DatabaseHelper).deleteDatabase();
      }
    }

    _initialized = false;
    _repository = null;
    _instance = null;

    if (shouldLog) {
      debugPrint('TinyLogs: Reset');
    }
  }

  /// Gets the current configuration
  TinyLogsConfig get config {
    _ensureInitialized();
    return _config;
  }

  /// Checks if TinyLogs is initialized
  bool get isInitialized => _initialized;

  /// Gets the underlying repository (for advanced usage)
  ///
  /// Allows direct access to [LogRepository] for advanced use cases
  /// or dependency injection in tests.
  LogRepository get repository {
    _ensureInitialized();
    return _repository!;
  }
}
