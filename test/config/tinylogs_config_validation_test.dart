import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinylogs/tinylogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialise sqflite pour les tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TinyLogsConfig validation', () {
    tearDown(() async {
      if (TinyLogs.instance.isInitialized) {
        await TinyLogs.instance.reset();
      }
    });

    test('init rejette une durée de rétention nulle', () async {
      expect(
        () => TinyLogs.instance.init(
          const TinyLogsConfig(retentionDuration: Duration.zero),
        ),
        throwsArgumentError,
      );
    });

    test('init rejette une durée de rétention négative', () async {
      expect(
        () => TinyLogs.instance.init(
          const TinyLogsConfig(retentionDuration: Duration(days: -1)),
        ),
        throwsArgumentError,
      );
    });

    test('init accepte une durée de rétention positive', () async {
      await TinyLogs.instance.init(
        const TinyLogsConfig(retentionDuration: Duration(days: 1)),
      );

      expect(TinyLogs.instance.isInitialized, isTrue);
    });
  });
}
