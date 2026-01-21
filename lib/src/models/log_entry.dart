import 'log_level.dart';

class LogEntry {
  /// Unique auto-generated identifier
  final int? id;

  /// Creation timestamp (in milliseconds since epoch)
  final int timestamp;

  /// Log content (non-null)
  final String content;

  /// Log severity level
  final LogLevel level;

  LogEntry({
    this.id,
    required this.timestamp,
    required this.content,
    this.level = LogLevel.info,
  }) : assert(content.isNotEmpty, 'Content cannot be empty');

  /// Creates a LogEntry with automatic timestamp
  factory LogEntry.now(String content, {LogLevel level = LogLevel.info}) {
    return LogEntry(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      content: content,
      level: level,
    );
  }

  /// Converts the LogEntry to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'content': content,
      'level': level.name,
    };
  }

  /// Creates a LogEntry from a SQLite Map
  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      timestamp: map['timestamp'] as int,
      content: map['content'] as String,
      level: map['level'] != null
          ? LogLevelExtension.fromString(map['level'] as String)
          : LogLevel.info,
    );
  }

  /// Returns the DateTime corresponding to the timestamp
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'LogEntry{id: $id, level: ${level.displayName}, timestamp: $timestamp (${dateTime.toIso8601String()}), content: $content}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          content == other.content &&
          level == other.level;

  @override
  int get hashCode =>
      id.hashCode ^ timestamp.hashCode ^ content.hashCode ^ level.hashCode;

  /// Copies the LogEntry with optional modifications
  LogEntry copyWith({
    int? id,
    int? timestamp,
    String? content,
    LogLevel? level,
  }) {
    return LogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
      level: level ?? this.level,
    );
  }
}
