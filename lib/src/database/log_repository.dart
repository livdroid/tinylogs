import '../models/log_entry.dart';
import '../models/log_level.dart';

/// Paginated result for log queries
class PaginatedLogs {
  /// List of logs for the current page
  final List<LogEntry> logs;

  /// Total count of logs (without pagination)
  final int totalCount;

  /// Current page number (starts at 0)
  final int page;

  /// Number of items per page
  final int pageSize;

  const PaginatedLogs({
    required this.logs,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  /// Total number of pages
  int get totalPages => (totalCount / pageSize).ceil();

  /// Indicates if there is a next page
  bool get hasNextPage => page < totalPages - 1;

  /// Indicates if there is a previous page
  bool get hasPreviousPage => page > 0;
}

/// Abstract interface for the log repository
///
/// This abstraction allows:
/// - Decoupling business logic from SQLite implementation
/// - Easier testing with mocks
/// - Easy switching to a different storage backend if needed
abstract class LogRepository {
  /// Inserts a log into the repository
  Future<int> insertLog(LogEntry log);

  /// Inserts multiple logs in a single transaction (batch)
  Future<List<int>> insertLogs(List<LogEntry> logs);

  /// Retrieves all logs
  Future<List<LogEntry>> getAllLogs();

  /// Retrieves logs with pagination
  Future<PaginatedLogs> getLogsPaginated({
    int page = 0,
    int pageSize = 50,
    LogLevel? minLevel,
  });

  /// Retrieves logs within a time range
  Future<List<LogEntry>> getLogsInRange(int startTimestamp, int endTimestamp);

  /// Retrieves logs around a specific date
  Future<List<LogEntry>> getLogsAround(
    DateTime dateTime, {
    Duration margin = const Duration(hours: 12),
  });

  /// Retrieves logs by minimum level
  Future<List<LogEntry>> getLogsByLevel(LogLevel minLevel);

  /// Deletes logs older than the specified duration
  Future<int> deleteOldLogs(Duration retentionDuration);

  /// Counts the total number of logs
  Future<int> getLogCount();

  /// Deletes all logs
  Future<int> deleteAllLogs();

  /// Closes the connection
  Future<void> close();

  /// Deletes the repository
  Future<void> deleteRepository();
}
