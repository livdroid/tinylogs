# TinyLogs

A simple and efficient Flutter package for logging information to a local SQLite database with automatic history management.

## Features

- **Local storage**: Uses SQLite via sqflite
- **Automatic management**: Automatic cleanup of old logs
- **Flexible search**: Retrieve logs by date range or around a specific date
- **Cross-platform**: Supports iOS, Android, macOS (and other platforms compatible with sqflite)
- **Tested**: Over 95% test coverage

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

You can customize the log retention duration and database name:

```dart
await TinyLogs.instance.init(
  const TinyLogsConfig(
    retentionDuration: Duration(days: 30), // Keep logs for 30 days
    databaseName: 'my_app_logs.db',       // Custom database name
  ),
);
```

### Recording a Log

```dart
await TinyLogs.instance.log('User logged in');
await TinyLogs.instance.log('Error loading data');
```

### Retrieving All Logs

```dart
final logs = await TinyLogs.instance.getAllLogs();

for (final log in logs) {
  print('${log.id}: ${log.content} - ${log.dateTime}');
}
```

### Retrieving Logs in a Date Range

```dart
final now = DateTime.now();
final yesterday = now.subtract(Duration(days: 1));

final logs = await TinyLogs.instance.getLogsInRange(yesterday, now);
```

### Retrieving Logs Around a Specific Date

By default, retrieves logs within 12 hours before and after the specified date:

```dart
final specificTime = DateTime(2024, 10, 15, 14, 30);
final logs = await TinyLogs.instance.getLogsAround(specificTime);
```

You can customize the margin:

```dart
final logs = await TinyLogs.instance.getLogsAround(
  specificTime,
  margin: Duration(hours: 6), // ±6 hours
);
```

### Cleaning Up Old Logs

Cleanup is automatic at startup, but you can also trigger it manually:

```dart
final deletedCount = await TinyLogs.instance.cleanupOldLogs();
print('$deletedCount old logs deleted');
```

### Counting Logs

```dart
final count = await TinyLogs.instance.getLogCount();
print('Total number of logs: $count');
```

### Deleting All Logs

```dart
await TinyLogs.instance.clearAllLogs();
```

## Data Model

Each log contains:

- `id`: Auto-generated unique identifier (int)
- `timestamp`: Timestamp in milliseconds since epoch (int)
- `content`: Log content (String, non-null)

```dart
class LogEntry {
  final int? id;
  final int timestamp;
  final String content;
  
  DateTime get dateTime; // Automatic timestamp conversion
}
```

## Configuration

### TinyLogsConfig

```dart
const TinyLogsConfig({
  Duration retentionDuration = const Duration(days: 7),  // Retention duration
  String databaseName = 'tinylogs.db',                   // Database name
});
```

## Complete Example

See the [`example/`](example/) folder for a complete application demonstrating all features.

To run the example:

```bash
cd example
flutter run
```

## Supported Platforms

- iOS
- Android
- macOS

## License

This project is licensed under the BSD-2-Clause License. See the [LICENSE](LICENSE) file for details.
