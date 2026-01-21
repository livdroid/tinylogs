import 'package:flutter_test/flutter_test.dart';
import 'package:tinylogs/tinylogs.dart';

void main() {
  group('LogLevel', () {
    test('has correct order using index', () {
      expect(LogLevel.debug.value, 0);
      expect(LogLevel.info.value, 1);
      expect(LogLevel.warning.value, 2);
      expect(LogLevel.error.value, 3);
    });

    test('value equals index', () {
      for (final level in LogLevel.values) {
        expect(level.value, level.index);
      }
    });

    test('displayName returns uppercase name', () {
      expect(LogLevel.debug.displayName, 'DEBUG');
      expect(LogLevel.info.displayName, 'INFO');
      expect(LogLevel.warning.displayName, 'WARNING');
      expect(LogLevel.error.displayName, 'ERROR');
    });

    test('fromString parses valid level names', () {
      expect(LogLevelExtension.fromString('debug'), LogLevel.debug);
      expect(LogLevelExtension.fromString('info'), LogLevel.info);
      expect(LogLevelExtension.fromString('warning'), LogLevel.warning);
      expect(LogLevelExtension.fromString('error'), LogLevel.error);
    });

    test('fromString is case insensitive', () {
      expect(LogLevelExtension.fromString('DEBUG'), LogLevel.debug);
      expect(LogLevelExtension.fromString('Info'), LogLevel.info);
      expect(LogLevelExtension.fromString('WARNING'), LogLevel.warning);
    });

    test('fromString returns info for invalid names', () {
      expect(LogLevelExtension.fromString('invalid'), LogLevel.info);
      expect(LogLevelExtension.fromString(''), LogLevel.info);
    });

    test('values are comparable by severity', () {
      expect(LogLevel.debug.value < LogLevel.info.value, isTrue);
      expect(LogLevel.info.value < LogLevel.warning.value, isTrue);
      expect(LogLevel.warning.value < LogLevel.error.value, isTrue);
    });
  });
}
