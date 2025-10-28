import 'package:flutter_test/flutter_test.dart';
import 'package:tinylogs/src/models/log_entry.dart';

void main() {
  group('LogEntry', () {
    test('crée un LogEntry avec tous les paramètres', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final entry = LogEntry(
        id: 1,
        timestamp: timestamp,
        content: 'Test log',
      );

      expect(entry.id, 1);
      expect(entry.timestamp, timestamp);
      expect(entry.content, 'Test log');
    });

    test('crée un LogEntry avec factory now()', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final entry = LogEntry.now('Test content');
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(entry.content, 'Test content');
      expect(entry.timestamp, greaterThanOrEqualTo(before));
      expect(entry.timestamp, lessThanOrEqualTo(after));
      expect(entry.id, isNull);
    });

    test('ne permet pas un contenu vide', () {
      expect(
        () => LogEntry(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          content: '',
        ),
        throwsAssertionError,
      );
    });

    test('convertit en Map correctement', () {
      final entry = LogEntry(
        id: 42,
        timestamp: 1234567890,
        content: 'Test',
      );

      final map = entry.toMap();

      expect(map['id'], 42);
      expect(map['timestamp'], 1234567890);
      expect(map['content'], 'Test');
    });

    test('crée un LogEntry depuis une Map', () {
      final map = {
        'id': 10,
        'timestamp': 9876543210,
        'content': 'From map',
      };

      final entry = LogEntry.fromMap(map);

      expect(entry.id, 10);
      expect(entry.timestamp, 9876543210);
      expect(entry.content, 'From map');
    });

    test('retourne la bonne DateTime', () {
      final dateTime = DateTime(2024, 1, 15, 10, 30);
      final entry = LogEntry(
        timestamp: dateTime.millisecondsSinceEpoch,
        content: 'Test',
      );

      expect(entry.dateTime, dateTime);
    });

    test('toString retourne une représentation lisible', () {
      final entry = LogEntry(
        id: 5,
        timestamp: 1234567890,
        content: 'Test log',
      );

      final str = entry.toString();

      expect(str, contains('id: 5'));
      expect(str, contains('timestamp: 1234567890'));
      expect(str, contains('content: Test log'));
    });

    test('equality fonctionne correctement', () {
      final entry1 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
      );

      final entry2 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
      );

      final entry3 = LogEntry(
        id: 2,
        timestamp: 1234567890,
        content: 'Different',
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('hashCode est cohérent avec equality', () {
      final entry1 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
      );

      final entry2 = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Same',
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('copyWith fonctionne correctement', () {
      final original = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Original',
      );

      final copied = original.copyWith(content: 'Modified');

      expect(copied.id, original.id);
      expect(copied.timestamp, original.timestamp);
      expect(copied.content, 'Modified');
    });

    test('copyWith sans paramètres retourne une copie identique', () {
      final original = LogEntry(
        id: 1,
        timestamp: 1234567890,
        content: 'Original',
      );

      final copied = original.copyWith();

      expect(copied, equals(original));
    });
  });
}
