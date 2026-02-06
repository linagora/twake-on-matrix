import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/utils/logging/log_orchestrator.dart';
import 'package:fluffychat/utils/logging/log_types.dart';
import 'package:fluffychat/utils/logging/logger.dart';
import 'package:fluffychat/utils/logging/log_filter.dart';
import 'package:fluffychat/utils/logging/filters/sensitive_data_filter.dart';

// Mock Logger
class MockLogger implements Logger {
  final List<LogEntry> logs = [];

  @override
  void log(LogEntry entry) {
    logs.add(entry);
  }
}

// Mock Filter (drops logs containing "drop")
class DropFilter implements LogFilter {
  @override
  LogEntry? filter(LogEntry entry) {
    if (entry.message.contains('drop')) {
      return null;
    }
    return entry;
  }
}

void main() {
  group('LogOrchestrator', () {
    late LogOrchestrator orchestrator;
    late MockLogger mockLogger;

    setUp(() {
      orchestrator = LogOrchestrator();

      mockLogger = MockLogger();
      orchestrator.addLogger(mockLogger);
    });

    tearDown(() {
      orchestrator.removeLogger(mockLogger);
    });

    test('should dispatch logs to subscribers', () {
      orchestrator.info('Test message');
      expect(mockLogger.logs.length, 1);
      expect(mockLogger.logs.first.message, 'Test message');
      expect(mockLogger.logs.first.level, LogLevel.info);
    });

    test('should apply filters (drop)', () {
      final dropFilter = DropFilter();
      orchestrator.addFilter(dropFilter);

      orchestrator.info('This message should be dropped');
      expect(
        mockLogger.logs.length,
        0,
      ); // Should be empty because message contains 'drop'

      orchestrator.info('This message passes');
      expect(mockLogger.logs.length, 1);

      orchestrator.removeFilter(dropFilter);
    });

    test('should apply SensitiveDataFilter', () {
      final filter = SensitiveDataFilter();
      orchestrator.addFilter(filter);

      orchestrator.info('Login attempt for token=abc12345');

      expect(mockLogger.logs.length, 1);
      final log = mockLogger.logs.first;
      expect(log.message, 'Login attempt for token=***REDACTED***');

      orchestrator.info(
        'Login attempt',
        context: {'password': 'supersecretpassword', 'user': 'admin'},
      );

      expect(mockLogger.logs.length, 2);
      final log2 = mockLogger.logs.last;
      expect(log2.context!['password'], '***REDACTED***');
      expect(log2.context!['user'], 'admin');

      orchestrator.removeFilter(filter);
    });
  });
}
