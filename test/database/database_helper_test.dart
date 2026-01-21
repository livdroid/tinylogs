import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinylogs/src/database/database_helper.dart';
import 'package:tinylogs/tinylogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper(
          databaseName:
              'test_logs_${DateTime.now().millisecondsSinceEpoch}.db');
    });

    tearDown(() async {
      await dbHelper.deleteDatabase();
    });

    test('inserts a log and retrieves it', () async {
      final log = LogEntry.now('Test log');
      final id = await dbHelper.insertLog(log);

      expect(id, greaterThan(0));

      final logs = await dbHelper.getAllLogs();
      expect(logs.length, 1);
      expect(logs.first.content, 'Test log');
      expect(logs.first.id, id);
    });

    test('inserts a log with level', () async {
      final log = LogEntry.now('Error log', level: LogLevel.error);
      await dbHelper.insertLog(log);

      final logs = await dbHelper.getAllLogs();
      expect(logs.first.level, LogLevel.error);
    });

    test('inserts multiple logs', () async {
      await dbHelper.insertLog(LogEntry.now('Log 1'));
      await dbHelper.insertLog(LogEntry.now('Log 2'));
      await dbHelper.insertLog(LogEntry.now('Log 3'));

      final logs = await dbHelper.getAllLogs();
      expect(logs.length, 3);
    });

    group('insertLogs (batch)', () {
      test('inserts multiple logs in batch', () async {
        final logs = [
          LogEntry.now('Batch 1'),
          LogEntry.now('Batch 2'),
          LogEntry.now('Batch 3'),
        ];

        final ids = await dbHelper.insertLogs(logs);

        expect(ids.length, 3);
        expect(ids.every((id) => id > 0), isTrue);

        final allLogs = await dbHelper.getAllLogs();
        expect(allLogs.length, 3);
      });

      test('returns empty list for empty input', () async {
        final ids = await dbHelper.insertLogs([]);
        expect(ids, isEmpty);
      });

      test('batch insert is atomic', () async {
        final logs = [
          LogEntry.now('Batch 1', level: LogLevel.debug),
          LogEntry.now('Batch 2', level: LogLevel.warning),
          LogEntry.now('Batch 3', level: LogLevel.error),
        ];

        await dbHelper.insertLogs(logs);

        final allLogs = await dbHelper.getAllLogs();
        expect(allLogs.any((l) => l.level == LogLevel.debug), isTrue);
        expect(allLogs.any((l) => l.level == LogLevel.warning), isTrue);
        expect(allLogs.any((l) => l.level == LogLevel.error), isTrue);
      });
    });

    test('getAllLogs returns logs sorted by timestamp descending', () async {
      final log1 = LogEntry(
        timestamp: DateTime.now()
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        content: 'Old',
      );
      final log2 = LogEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        content: 'Recent',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);

      final logs = await dbHelper.getAllLogs();
      expect(logs.first.content, 'Recent');
      expect(logs.last.content, 'Old');
    });

    group('getLogsPaginated', () {
      test('returns paginated results', () async {
        for (int i = 0; i < 10; i++) {
          await dbHelper.insertLog(LogEntry.now('Log $i'));
        }

        final page0 = await dbHelper.getLogsPaginated(page: 0, pageSize: 3);
        expect(page0.logs.length, 3);
        expect(page0.totalCount, 10);
        expect(page0.page, 0);
        expect(page0.pageSize, 3);
        expect(page0.totalPages, 4);
        expect(page0.hasNextPage, isTrue);
        expect(page0.hasPreviousPage, isFalse);

        final page1 = await dbHelper.getLogsPaginated(page: 1, pageSize: 3);
        expect(page1.logs.length, 3);
        expect(page1.hasNextPage, isTrue);
        expect(page1.hasPreviousPage, isTrue);

        final page3 = await dbHelper.getLogsPaginated(page: 3, pageSize: 3);
        expect(page3.logs.length, 1);
        expect(page3.hasNextPage, isFalse);
      });

      test('filters by minimum level', () async {
        await dbHelper.insertLog(LogEntry.now('Debug', level: LogLevel.debug));
        await dbHelper.insertLog(LogEntry.now('Info', level: LogLevel.info));
        await dbHelper.insertLog(LogEntry.now('Warning', level: LogLevel.warning));
        await dbHelper.insertLog(LogEntry.now('Error', level: LogLevel.error));

        final warningAndAbove = await dbHelper.getLogsPaginated(
          minLevel: LogLevel.warning,
        );

        expect(warningAndAbove.totalCount, 2);
        expect(warningAndAbove.logs.every(
          (l) => l.level == LogLevel.warning || l.level == LogLevel.error,
        ), isTrue);
      });

      test('returns empty page for out of range', () async {
        await dbHelper.insertLog(LogEntry.now('Log 1'));

        final outOfRange = await dbHelper.getLogsPaginated(page: 10, pageSize: 50);
        expect(outOfRange.logs, isEmpty);
        expect(outOfRange.totalCount, 1);
      });
    });

    test('getLogsInRange retrieves logs in the range', () async {
      final now = DateTime.now();
      final log1 = LogEntry(
        timestamp:
            now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        content: 'Before range',
      );
      final log2 = LogEntry(
        timestamp:
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        content: 'In range',
      );
      final log3 = LogEntry(
        timestamp: now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        content: 'After range',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);
      await dbHelper.insertLog(log3);

      final startTime =
          now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      final endTime = now.millisecondsSinceEpoch;

      final logs = await dbHelper.getLogsInRange(startTime, endTime);

      expect(logs.length, 1);
      expect(logs.first.content, 'In range');
    });

    test('getLogsAround retrieves logs around a date', () async {
      final centerTime = DateTime.now();

      final log1 = LogEntry(
        timestamp: centerTime
            .subtract(const Duration(hours: 15))
            .millisecondsSinceEpoch,
        content: 'Too old',
      );
      final log2 = LogEntry(
        timestamp: centerTime
            .subtract(const Duration(hours: 6))
            .millisecondsSinceEpoch,
        content: 'Before center',
      );
      final log3 = LogEntry(
        timestamp: centerTime.millisecondsSinceEpoch,
        content: 'Center',
      );
      final log4 = LogEntry(
        timestamp:
            centerTime.add(const Duration(hours: 6)).millisecondsSinceEpoch,
        content: 'After center',
      );
      final log5 = LogEntry(
        timestamp:
            centerTime.add(const Duration(hours: 15)).millisecondsSinceEpoch,
        content: 'Too recent',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);
      await dbHelper.insertLog(log3);
      await dbHelper.insertLog(log4);
      await dbHelper.insertLog(log5);

      final logs = await dbHelper.getLogsAround(centerTime);

      expect(logs.length, 3);
      expect(logs.any((log) => log.content == 'Before center'), isTrue);
      expect(logs.any((log) => log.content == 'Center'), isTrue);
      expect(logs.any((log) => log.content == 'After center'), isTrue);
      expect(logs.any((log) => log.content == 'Too old'), isFalse);
      expect(logs.any((log) => log.content == 'Too recent'), isFalse);
    });

    test('getLogsAround accepts custom margin', () async {
      final centerTime = DateTime.now();

      final log1 = LogEntry(
        timestamp: centerTime
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        content: 'Too old',
      );
      final log2 = LogEntry(
        timestamp: centerTime.millisecondsSinceEpoch,
        content: 'Center',
      );
      final log3 = LogEntry(
        timestamp:
            centerTime.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
        content: 'Close',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);
      await dbHelper.insertLog(log3);

      final logs = await dbHelper.getLogsAround(
        centerTime,
        margin: const Duration(hours: 1),
      );

      expect(logs.length, 2);
      expect(logs.any((log) => log.content == 'Center'), isTrue);
      expect(logs.any((log) => log.content == 'Close'), isTrue);
      expect(logs.any((log) => log.content == 'Too old'), isFalse);
    });

    group('getLogsByLevel', () {
      test('filters logs by minimum level', () async {
        await dbHelper.insertLog(LogEntry.now('Debug', level: LogLevel.debug));
        await dbHelper.insertLog(LogEntry.now('Info', level: LogLevel.info));
        await dbHelper.insertLog(LogEntry.now('Warning', level: LogLevel.warning));
        await dbHelper.insertLog(LogEntry.now('Error', level: LogLevel.error));

        final errors = await dbHelper.getLogsByLevel(LogLevel.error);
        expect(errors.length, 1);
        expect(errors.first.level, LogLevel.error);

        final warningAndAbove = await dbHelper.getLogsByLevel(LogLevel.warning);
        expect(warningAndAbove.length, 2);

        final infoAndAbove = await dbHelper.getLogsByLevel(LogLevel.info);
        expect(infoAndAbove.length, 3);

        final all = await dbHelper.getLogsByLevel(LogLevel.debug);
        expect(all.length, 4);
      });
    });

    test('deleteOldLogs removes old logs', () async {
      final now = DateTime.now();
      final oldLog = LogEntry(
        timestamp:
            now.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
        content: 'Old',
      );
      final recentLog = LogEntry(
        timestamp: now.millisecondsSinceEpoch,
        content: 'Recent',
      );

      await dbHelper.insertLog(oldLog);
      await dbHelper.insertLog(recentLog);

      final deletedCount =
          await dbHelper.deleteOldLogs(const Duration(days: 7));

      expect(deletedCount, 1);

      final remainingLogs = await dbHelper.getAllLogs();
      expect(remainingLogs.length, 1);
      expect(remainingLogs.first.content, 'Recent');
    });

    test('getLogCount returns correct count', () async {
      expect(await dbHelper.getLogCount(), 0);

      await dbHelper.insertLog(LogEntry.now('Log 1'));
      expect(await dbHelper.getLogCount(), 1);

      await dbHelper.insertLog(LogEntry.now('Log 2'));
      await dbHelper.insertLog(LogEntry.now('Log 3'));
      expect(await dbHelper.getLogCount(), 3);
    });

    test('deleteAllLogs removes all logs', () async {
      await dbHelper.insertLog(LogEntry.now('Log 1'));
      await dbHelper.insertLog(LogEntry.now('Log 2'));
      await dbHelper.insertLog(LogEntry.now('Log 3'));

      final deletedCount = await dbHelper.deleteAllLogs();

      expect(deletedCount, 3);
      expect(await dbHelper.getLogCount(), 0);
    });

    test('close closes the database', () async {
      await dbHelper.database; // Initialize the db
      await dbHelper.close();

      // After close, accessing database should reinitialize
      final db = await dbHelper.database;
      expect(db, isNotNull);
    });
  });
}
