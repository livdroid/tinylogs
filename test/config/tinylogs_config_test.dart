import 'package:flutter_test/flutter_test.dart';
import 'package:tinylogs/src/config/tinylogs_config.dart';

void main() {
  group('TinyLogsConfig', () {
    test('uses default values', () {
      const config = TinyLogsConfig();

      expect(config.retentionDuration, const Duration(days: 7));
      expect(config.databaseName, 'tinylogs.db');
      expect(config.enableLogs, true);
    });

    test('accepts custom retention duration', () {
      const config = TinyLogsConfig(
        retentionDuration: Duration(days: 30),
      );

      expect(config.retentionDuration, const Duration(days: 30));
    });

    test('accepts custom database name', () {
      const config = TinyLogsConfig(
        databaseName: 'custom_logs.db',
      );

      expect(config.databaseName, 'custom_logs.db');
    });

    test('accepts custom enableLogs', () {
      const configEnabled = TinyLogsConfig(enableLogs: true);
      expect(configEnabled.enableLogs, true);

      const configDisabled = TinyLogsConfig(enableLogs: false);
      expect(configDisabled.enableLogs, false);
    });

    test('accepts all custom parameters', () {
      const config = TinyLogsConfig(
        retentionDuration: Duration(hours: 48),
        databaseName: 'my_app_logs.db',
        enableLogs: false,
      );

      expect(config.retentionDuration, const Duration(hours: 48));
      expect(config.databaseName, 'my_app_logs.db');
      expect(config.enableLogs, false);
    });

    test('accepts zero or negative retention duration at construction', () {
      // Validation is done at init, not construction
      const config1 = TinyLogsConfig(retentionDuration: Duration.zero);
      expect(config1.retentionDuration, Duration.zero);

      const config2 = TinyLogsConfig(retentionDuration: Duration(days: -1));
      expect(config2.retentionDuration, const Duration(days: -1));
    });

    test('toString returns a readable representation', () {
      const config = TinyLogsConfig(
        retentionDuration: Duration(days: 14),
        databaseName: 'test.db',
        enableLogs: false,
      );

      final str = config.toString();

      expect(str, contains('retentionDuration'));
      expect(str, contains('databaseName'));
      expect(str, contains('enableLogs'));
    });
  });
}
