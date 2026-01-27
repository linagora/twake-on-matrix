import '../log_filter.dart';
import '../log_types.dart';

class SensitiveDataFilter implements LogFilter {
  final List<String> sensitiveKeys;
  final String replacement;

  SensitiveDataFilter({
    this.sensitiveKeys = const [
      'password',
      'token',
      'access_token',
      'secret',
      'authorization',
    ],
    this.replacement = '***REDACTED***',
  });

  @override
  LogEntry? filter(LogEntry entry) {
    String newMessage = entry.message;

    for (final key in sensitiveKeys) {
      // Create a regex to find the key and its value
      // Matches:
      // 1. key=value
      // 2. key: value
      // 3. "key": "value"
      // Groups:
      // 1: The key literal
      // 2: The separator (= or :)
      // 3: The value (quoted or unquoted)
      final regex = RegExp(
        '($key)([\\s":=]+)(?:"([^"]+)"|([^,\\s}]+))',
        caseSensitive: false,
      );

      newMessage = newMessage.replaceAllMapped(regex, (match) {
        // Keep key and separator, replace value
        return '${match.group(1)}${match.group(2)}$replacement';
      });
    }

    // Redact known sensitive keys in the context
    Map<String, dynamic>? newContext;
    if (entry.context != null) {
      newContext = {};
      entry.context!.forEach((key, value) {
        if (sensitiveKeys.contains(key.toLowerCase())) {
          newContext![key] = replacement;
        } else {
          newContext![key] = value;
        }
      });
    }

    return entry.copyWith(
      message: newMessage,
      context: newContext ?? entry.context,
    );
  }
}
