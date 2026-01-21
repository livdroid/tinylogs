# TinyLogs

A simple and efficient Flutter package for logging information to a local SQLite database with automatic history management.

## Features

- **Log Levels**: Support for debug, info, warning, and error levels
- **Local Storage**: Uses SQLite via sqflite
- **Automatic Cleanup**: Automatic removal of old logs based on retention duration
- **Flexible Search**: Retrieve logs by date range, around a specific date, or by severity level
- **Pagination**: Efficient retrieval of large log collections
- **Batch Insert**: Insert multiple logs in a single transaction
- **Real-time Stream**: Subscribe to new logs as they are recorded
- **Export**: Export logs to JSON or CSV format (no third-party dependencies)
- **Cross-platform**: Supports iOS, Android, macOS
- **Testable**: Abstract repository interface for easy mocking
- **Tested**: Over 95% test coverage

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  tinylogs: ^2.0.0
```

## Basic Usage

### Initialization

Initialize TinyLogs at application startup:

```dart
import 'package:tinylogs/tinylogs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with default configuration (7 days retention)
  await TinyLogs.instance.init();

  runApp(MyApp());
}
```

### Custom Configuration

```dart
await TinyLogs.instance.init(
  const TinyLogsConfig(
    retentionDuration: Duration(days: 30), // Keep logs for 30 days
    databaseName: 'my_app_logs.db',        // Custom database name
  ),
);
```

## Logging

### Basic Logging

```dart
await TinyLogs.instance.log('User logged in');
await TinyLogs.instance.log('Something happened', level: LogLevel.warning);
```

### Log Level Methods

Convenient methods for each log level:

```dart
await TinyLogs.instance.debug('Detailed debug info');
await TinyLogs.instance.info('User completed action');
await TinyLogs.instance.warning('Rate limit approaching');
await TinyLogs.instance.error('Failed to load data');
```

### Batch Insert

Insert multiple logs efficiently in a single transaction:

```dart
await TinyLogs.instance.logBatch([
  'Step 1 completed',
  'Step 2 completed',
  'Step 3 completed',
], level: LogLevel.info);
```

## Retrieving Logs

### Get All Logs

```dart
final logs = await TinyLogs.instance.getAllLogs();

for (final log in logs) {
  print('[${log.level.displayName}] ${log.content} - ${log.dateTime}');
}
```

### Pagination

For large log collections, use pagination:

```dart
final page = await TinyLogs.instance.getLogsPaginated(
  page: 0,
  pageSize: 50,
  minLevel: LogLevel.warning, // Optional: filter by minimum level
);

print('Page ${page.page + 1} of ${page.totalPages}');
print('Total logs: ${page.totalCount}');
print('Has next page: ${page.hasNextPage}');

for (final log in page.logs) {
  print(log.content);
}
```

### Filter by Log Level

```dart
// Get only warnings and errors
final criticalLogs = await TinyLogs.instance.getLogsByLevel(LogLevel.warning);
```

### Filter by Date Range

```dart
final now = DateTime.now();
final yesterday = now.subtract(Duration(days: 1));

final logs = await TinyLogs.instance.getLogsInRange(yesterday, now);
```

### Filter Around a Specific Date

```dart
final specificTime = DateTime(2024, 10, 15, 14, 30);

// Default: ±12 hours
final logs = await TinyLogs.instance.getLogsAround(specificTime);

// Custom margin: ±6 hours
final logs = await TinyLogs.instance.getLogsAround(
  specificTime,
  margin: Duration(hours: 6),
);
```

## Real-time Stream

Subscribe to new logs as they are recorded:

```dart
TinyLogs.instance.logStream.listen((log) {
  print('New log: [${log.level.displayName}] ${log.content}');

  // Show notification for errors
  if (log.level == LogLevel.error) {
    showErrorNotification(log.content);
  }
});
```

## Export

### Export to JSON

```dart
final json = await TinyLogs.instance.exportToJson();
// Save to file or send to server

// Or export a subset
final errors = await TinyLogs.instance.getLogsByLevel(LogLevel.error);
final errorJson = await TinyLogs.instance.exportToJson(logs: errors);
```

Example JSON output:
```json
[
  {
    "id": 1,
    "timestamp": 1705312800000,
    "dateTime": "2024-01-15T10:00:00.000",
    "level": "error",
    "content": "Failed to connect to server"
  }
]
```

### Export to CSV

```dart
final csv = await TinyLogs.instance.exportToCsv();
// Save to file

// Or export a subset
final todayLogs = await TinyLogs.instance.getLogsInRange(today, now);
final todayCsv = await TinyLogs.instance.exportToCsv(logs: todayLogs);
```

## Maintenance

### Count Logs

```dart
final count = await TinyLogs.instance.getLogCount();
print('Total logs: $count');
```

### Manual Cleanup

Cleanup is automatic at startup, but can be triggered manually:

```dart
final deletedCount = await TinyLogs.instance.cleanupOldLogs();
print('$deletedCount old logs deleted');
```

### Clear All Logs

```dart
await TinyLogs.instance.clearAllLogs();
```

### Close Database

```dart
await TinyLogs.instance.close();
```

## Data Models

### LogEntry

```dart
class LogEntry {
  final int? id;           // Auto-generated unique identifier
  final int timestamp;     // Milliseconds since epoch
  final String content;    // Log content
  final LogLevel level;    // Severity level

  DateTime get dateTime;   // Automatic timestamp conversion
}
```

### LogLevel

```dart
enum LogLevel {
  debug,    // Detailed debug information
  info,     // General operational information
  warning,  // Abnormal but non-critical situations
  error,    // Errors requiring attention
}
```

### PaginatedLogs

```dart
class PaginatedLogs {
  final List<LogEntry> logs;  // Logs for current page
  final int totalCount;       // Total log count
  final int page;             // Current page (0-indexed)
  final int pageSize;         // Items per page

  int get totalPages;
  bool get hasNextPage;
  bool get hasPreviousPage;
}
```

### TinyLogsConfig

```dart
const TinyLogsConfig({
  Duration retentionDuration = const Duration(days: 7),
  String databaseName = 'tinylogs.db',
  bool enableLogs = true,  // Enable/disable debug prints
});
```

### Disable Debug Prints

To silence TinyLogs debug messages in the console:

```dart
await TinyLogs.instance.init(
  const TinyLogsConfig(
    enableLogs: false,  // No debug prints
  ),
);
```

## Advanced Usage

### Access the Repository

For advanced use cases or testing, you can access the underlying repository:

```dart
final repository = TinyLogs.instance.repository;

// Use for custom queries or mock in tests
```

### Database Migration

TinyLogs automatically handles database migrations when updating from previous versions. The `level` column is added automatically for databases created with version 1.

## Complete Example

See the [`example/`](example/) folder for a complete application demonstrating all features.

```bash
cd example
flutter run
```

## Supported Platforms

- iOS
- Android
- macOS

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

This project is licensed under the BSD-2-Clause License. See the [LICENSE](LICENSE) file for details.
