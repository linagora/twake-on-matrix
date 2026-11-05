import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/homeserver_picker/homeserver_input.dart';

void main() {
  group('parseHomeserverInput', () {
    final cases = {
      'matrix.example.com': Uri.parse('https://matrix.example.com'),
      'matrix.example.com:8443': Uri.parse('https://matrix.example.com:8443'),
      '192.168.88.253:8443': Uri.parse('https://192.168.88.253:8443'),
      'localhost:8083': Uri.parse('https://localhost:8083'),
      'matrix.example.com:8443/': Uri.parse('https://matrix.example.com:8443/'),
      'https://matrix.example.com:8443': Uri.parse(
        'https://matrix.example.com:8443',
      ),
      'http://localhost:8083': Uri.parse('http://localhost:8083'),
    };

    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('parses "$input"', () {
        final uri = parseHomeserverInput(input);

        expect(uri, expected);
        expect(uri.host, isNotEmpty);
      });
    }

    test('keeps the port', () {
      expect(parseHomeserverInput('matrix.example.com:8443').port, 8443);
    });
  });
}
