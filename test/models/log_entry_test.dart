import 'package:flutter_test/flutter_test.dart';
import 'package:tinylogs/tinylogs.dart';

void main() {
  group('LogEntry', () {
    test('creates a LogEntry with all parameters', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final entry = LogEntry(
        id: 1,
        timestamp: timestamp,
        content: 'Test log',
        level: LogLevel.warning,
      );

      expect(entry.id, 1);
      expect(entry.timestamp, timestamp);
      expect(entry.content, 'Test log');
      expect(entry.level, LogLevel.warning);
    });

    test('creates a LogEntry with factory now()', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final entry = LogEntry.now('Test content');
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(entry.content, 'Test content');
      expect(entry.timestamp, greaterThanOrEqualTo(before));
      expect(entry.timestamp, lessThanOrEqualTo(after));
      expect(entry.id, isNull);
      expect(entry.level, LogLevel.info); // Default level
    });

    test('creates a LogEntry with factory now() and custom level', () {
      final entry = LogEntry.now('Error message', level: LogLevel.error);

      expect(entry.content, 'Error message');
      expect(entry.level, LogLevel.error);
    });

    test('defaults to info level', () {
      final entry = LogEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        content: 'Test',
      );

      expect(entry.level, LogLevel.info);
    });

    test('does not allow empty content', () {
      expect(
        () => LogEntry(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          content: '',
        ),
        throwsAssertionError,
      );
    });

    test('converts to Map correctly', () {
      final entry = LogEntry(
        id: 42,
        timestamp: 1234567890,
        content: 'Test',
        level: LogLevel.error,
      );

      final map = entry.toMap();

      expect(map['id'], 42);
      expect(map['timestamp'], 1234567890);
      expect(map['content'], 'Test');
      expect(map['level'], 'error');
    });

    test('creates a LogEntry from a Map', () {
      final map = {
        'id': 10,
        'timestamp': 9876543210,
        'content': 'From map',
        'level': 'warning',
      };

      final entry = LogEntry.fromMap(map);

      expect(entry.id, 10);
      expect(entry.timestamp, 9876543210);
      expect(entry.content, 'From map');
      expect(entry.level, LogLevel.warning);
    });

    test('creates a LogEntry from a Map without level (defaults to info)', () {
      final map = {
        'id': 10,
        'timestamp': 9876543210,
        'content': 'From map',
      };

      final entry = LogEntry.fromMap(map);
      expect(entry.level, LogLevel.info);
    });

    test('returns the correct DateTime', () {
      final dateTime = DateTime(2024, 1, 15, 10, 30);
      final entry = LogEntry(
        timestamp: dateTime.millisecondsSinceEpoch,
        content: 'Test',
      );

      expect(entry.dateTime, dateTime);
    });

    test('toString returns a readable representation', () {
      final entry = LogEntry(
        id: 5,
        timestamp: 1234567890,
        content: 'Test log',
        level: LogLevel.warning,
      );

      final str = entry.toString();

      expect(str, contains('id: 5'));
      expect(str, contains('level: WARNING'));
      expect(str, contains('timestamp: 1234567890'));
      expect(str, contains('content: Test log'));
    });

    test('equality works correctly', () {
      final entry1 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
        level: LogLevel.info,
      );

      final entry2 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
        level: LogLevel.info,
      );

      final entry3 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
        level: LogLevel.error, // Different level
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('hashCode is consistent with equality', () {
      final entry1 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
        level: LogLevel.warning,
      );

      final entry2 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
        level: LogLevel.warning,
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('copyWith works correctly', () {
      final original = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Original',
        level: LogLevel.debug,
      );

      final copied = original.copyWith(content: 'Modified', level: LogLevel.error);

      expect(copied.id, original.id);
      expect(copied.timestamp, original.timestamp);
      expect(copied.content, 'Modified');
      expect(copied.level, LogLevel.error);
    });

    test('copyWith without parameters returns an identical copy', () {
      final original = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Original',
        level: LogLevel.warning,
      );

      final copied = original.copyWith();

      expect(copied, equals(original));
    });
  });
}
