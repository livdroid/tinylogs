import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinylogs/tinylogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TinyLogs', () {
    late TinyLogs tinyLogs;

    setUp(() async {
      tinyLogs = TinyLogs.instance;
      // Use a unique db name for each test
      await tinyLogs.init(TinyLogsConfig(
        databaseName: 'test_${DateTime.now().millisecondsSinceEpoch}.db',
      ));
    });

    tearDown(() async {
      await tinyLogs.reset();
    });

    test('instance returns the same singleton', () {
      final instance1 = TinyLogs.instance;
      final instance2 = TinyLogs.instance;

      expect(instance1, same(instance2));
    });

    test('init initializes correctly', () async {
      expect(tinyLogs.isInitialized, isTrue);
    });

    test('init with custom config', () async {
      await tinyLogs.reset();

      const customConfig = TinyLogsConfig(
        retentionDuration: Duration(days: 14),
        databaseName: 'custom_test.db',
      );

      await tinyLogs.init(customConfig);

      expect(tinyLogs.config.retentionDuration, const Duration(days: 14));
      expect(tinyLogs.config.databaseName, 'custom_test.db');
    });

    group('Basic logging', () {
      test('log records a message', () async {
        final id = await tinyLogs.log('Test message');

        expect(id, greaterThan(0));

        final logs = await tinyLogs.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.content, 'Test message');
        expect(logs.first.level, LogLevel.info); // Default level
      });

      test('log with custom level', () async {
        await tinyLogs.log('Error message', level: LogLevel.error);

        final logs = await tinyLogs.getAllLogs();
        expect(logs.first.level, LogLevel.error);
      });

      test('log rejects empty content', () async {
        expect(
          () => tinyLogs.log(''),
          throwsArgumentError,
        );
      });

      test('log without init throws error', () async {
        await tinyLogs.reset();

        expect(
          () => tinyLogs.log('Test'),
          throwsStateError,
        );
      });
    });

    group('Log level methods', () {
      test('debug() records debug level', () async {
        await tinyLogs.debug('Debug message');

        final logs = await tinyLogs.getAllLogs();
        expect(logs.first.level, LogLevel.debug);
        expect(logs.first.content, 'Debug message');
      });

      test('info() records info level', () async {
        await tinyLogs.info('Info message');

        final logs = await tinyLogs.getAllLogs();
        expect(logs.first.level, LogLevel.info);
      });

      test('warning() records warning level', () async {
        await tinyLogs.warning('Warning message');

        final logs = await tinyLogs.getAllLogs();
        expect(logs.first.level, LogLevel.warning);
      });

      test('error() records error level', () async {
        await tinyLogs.error('Error message');

        final logs = await tinyLogs.getAllLogs();
        expect(logs.first.level, LogLevel.error);
      });
    });

    group('Batch insert', () {
      test('logBatch inserts multiple logs', () async {
        final ids = await tinyLogs.logBatch(['Log 1', 'Log 2', 'Log 3']);

        expect(ids.length, 3);
        expect(await tinyLogs.getLogCount(), 3);
      });

      test('logBatch with custom level', () async {
        await tinyLogs.logBatch(['Error 1', 'Error 2'], level: LogLevel.error);

        final logs = await tinyLogs.getAllLogs();
        expect(logs.every((l) => l.level == LogLevel.error), isTrue);
      });

      test('logBatch filters empty strings', () async {
        final ids = await tinyLogs.logBatch(['Log 1', '', 'Log 2', '']);

        expect(ids.length, 2);
      });

      test('logBatch returns empty list for empty input', () async {
        final ids = await tinyLogs.logBatch([]);
        expect(ids, isEmpty);
      });
    });

    group('Log retrieval', () {
      test('getAllLogs returns all logs', () async {
        await tinyLogs.log('Log 1');
        await tinyLogs.log('Log 2');
        await tinyLogs.log('Log 3');

        final logs = await tinyLogs.getAllLogs();

        expect(logs.length, 3);
      });

      test('getLogsPaginated returns paginated results', () async {
        for (int i = 0; i < 15; i++) {
          await tinyLogs.log('Log $i');
        }

        final page0 = await tinyLogs.getLogsPaginated(page: 0, pageSize: 5);
        expect(page0.logs.length, 5);
        expect(page0.totalCount, 15);
        expect(page0.hasNextPage, isTrue);
        expect(page0.hasPreviousPage, isFalse);

        final page2 = await tinyLogs.getLogsPaginated(page: 2, pageSize: 5);
        expect(page2.logs.length, 5);
        expect(page2.hasNextPage, isFalse);
        expect(page2.hasPreviousPage, isTrue);
      });

      test('getLogsPaginated filters by level', () async {
        await tinyLogs.debug('Debug');
        await tinyLogs.info('Info');
        await tinyLogs.warning('Warning');
        await tinyLogs.error('Error');

        final result = await tinyLogs.getLogsPaginated(minLevel: LogLevel.warning);
        expect(result.totalCount, 2);
      });

      test('getLogsInRange filters correctly', () async {
        final now = DateTime.now();

        await Future.delayed(const Duration(milliseconds: 10));
        await tinyLogs.log('Log in range');
        await Future.delayed(const Duration(milliseconds: 10));

        final start = now.subtract(const Duration(minutes: 1));
        final end = now.add(const Duration(minutes: 1));

        final logs = await tinyLogs.getLogsInRange(start, end);

        expect(logs.length, 1);
        expect(logs.first.content, 'Log in range');
      });

      test('getLogsInRange rejects invalid range', () async {
        final start = DateTime.now();
        final end = start.subtract(const Duration(hours: 1));

        expect(
          () => tinyLogs.getLogsInRange(start, end),
          throwsArgumentError,
        );
      });

      test('getLogsAround retrieves logs around a date', () async {
        final centerTime = DateTime.now();

        await tinyLogs.log('Old');
        await Future.delayed(const Duration(milliseconds: 5));

        final recentLog = LogEntry(
          timestamp: centerTime.millisecondsSinceEpoch,
          content: 'In range',
        );
        await tinyLogs.log(recentLog.content);

        final logs = await tinyLogs.getLogsAround(
          centerTime,
          margin: const Duration(seconds: 30),
        );

        expect(logs.isNotEmpty, isTrue);
      });

      test('getLogsByLevel filters by minimum level', () async {
        await tinyLogs.debug('Debug');
        await tinyLogs.info('Info');
        await tinyLogs.warning('Warning');
        await tinyLogs.error('Error');

        final warningAndAbove = await tinyLogs.getLogsByLevel(LogLevel.warning);
        expect(warningAndAbove.length, 2);
        expect(warningAndAbove.every(
          (l) => l.level == LogLevel.warning || l.level == LogLevel.error,
        ), isTrue);
      });
    });

    group('Log stream', () {
      test('logStream emits new logs', () async {
        final completer = Completer<LogEntry>();
        final subscription = tinyLogs.logStream.listen((log) {
          if (!completer.isCompleted) {
            completer.complete(log);
          }
        });

        await tinyLogs.log('Stream test');

        final receivedLog = await completer.future.timeout(
          const Duration(seconds: 1),
        );

        expect(receivedLog.content, 'Stream test');

        await subscription.cancel();
      });

      test('logStream emits logs from batch', () async {
        final logs = <LogEntry>[];
        final subscription = tinyLogs.logStream.listen(logs.add);

        await tinyLogs.logBatch(['Batch 1', 'Batch 2', 'Batch 3']);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(logs.length, 3);

        await subscription.cancel();
      });

      test('logStream includes log level', () async {
        final completer = Completer<LogEntry>();
        final subscription = tinyLogs.logStream.listen((log) {
          if (!completer.isCompleted) {
            completer.complete(log);
          }
        });

        await tinyLogs.error('Error stream test');

        final receivedLog = await completer.future.timeout(
          const Duration(seconds: 1),
        );

        expect(receivedLog.level, LogLevel.error);

        await subscription.cancel();
      });
    });

    group('Export', () {
      test('exportToJson returns valid JSON', () async {
        await tinyLogs.debug('Debug log');
        await tinyLogs.error('Error log');

        final json = await tinyLogs.exportToJson();

        final decoded = jsonDecode(json) as List;
        expect(decoded.length, 2);
        expect(decoded.first['level'], isNotNull);
        expect(decoded.first['content'], isNotNull);
        expect(decoded.first['timestamp'], isNotNull);
        expect(decoded.first['dateTime'], isNotNull);
      });

      test('exportToJson with custom logs', () async {
        await tinyLogs.log('Log 1');
        await tinyLogs.log('Log 2');
        await tinyLogs.log('Log 3');

        final allLogs = await tinyLogs.getAllLogs();
        final subset = [allLogs.first];

        final json = await tinyLogs.exportToJson(logs: subset);

        final decoded = jsonDecode(json) as List;
        expect(decoded.length, 1);
      });

      test('exportToCsv returns valid CSV', () async {
        await tinyLogs.info('Test log');

        final csv = await tinyLogs.exportToCsv();

        expect(csv, contains('id,timestamp,dateTime,level,content'));
        expect(csv, contains('info'));
        expect(csv, contains('Test log'));
      });

      test('exportToCsv escapes special characters', () async {
        await tinyLogs.log('Log with, comma');
        await tinyLogs.log('Log with "quotes"');

        final csv = await tinyLogs.exportToCsv();

        // Commas and quotes should be escaped
        expect(csv, contains('"Log with, comma"'));
        expect(csv, contains('"Log with ""quotes"""'));
      });

      test('exportToCsv with custom logs', () async {
        await tinyLogs.log('Log 1');
        await tinyLogs.log('Log 2');

        final allLogs = await tinyLogs.getAllLogs();
        final subset = [allLogs.first];

        final csv = await tinyLogs.exportToCsv(logs: subset);

        final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines.length, 2); // Header + 1 log
      });
    });

    group('Maintenance', () {
      test('getLogCount returns correct count', () async {
        expect(await tinyLogs.getLogCount(), 0);

        await tinyLogs.log('Log 1');
        expect(await tinyLogs.getLogCount(), 1);

        await tinyLogs.log('Log 2');
        await tinyLogs.log('Log 3');
        expect(await tinyLogs.getLogCount(), 3);
      });

      test('cleanupOldLogs removes old logs', () async {
        await tinyLogs.reset();

        const config = TinyLogsConfig(
          retentionDuration: Duration(days: 1),
          databaseName: 'cleanup_test.db',
        );
        await tinyLogs.init(config);

        await tinyLogs.log('New log');

        final deletedCount = await tinyLogs.cleanupOldLogs();

        expect(deletedCount, 0);
        expect(await tinyLogs.getLogCount(), 1);
      });

      test('clearAllLogs removes all logs', () async {
        await tinyLogs.log('Log 1');
        await tinyLogs.log('Log 2');
        await tinyLogs.log('Log 3');

        expect(await tinyLogs.getLogCount(), 3);

        final deletedCount = await tinyLogs.clearAllLogs();

        expect(deletedCount, 3);
        expect(await tinyLogs.getLogCount(), 0);
      });

      test('close closes the database', () async {
        await tinyLogs.close();
        expect(tinyLogs.isInitialized, isFalse);
      });

      test('reset completely resets', () async {
        await tinyLogs.log('Test');
        expect(await tinyLogs.getLogCount(), 1);

        await tinyLogs.reset();

        expect(tinyLogs.isInitialized, isFalse);
      });
    });

    group('Repository access', () {
      test('repository returns the underlying repository', () {
        final repo = tinyLogs.repository;
        expect(repo, isA<LogRepository>());
      });

      test('config returns the configuration', () {
        final config = tinyLogs.config;
        expect(config, isNotNull);
        expect(config.retentionDuration, isNotNull);
        expect(config.databaseName, isNotNull);
      });
    });

    test('multiple logs in sequence', () async {
      for (int i = 0; i < 10; i++) {
        await tinyLogs.log('Log $i');
      }

      final logs = await tinyLogs.getAllLogs();
      expect(logs.length, 10);
    });
  });
}
