import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/presentation/extensions/homeserver_picker/homeserver_input_extension.dart';

void main() {
  group('toHomeserverUri', () {
    final cases = {
      'matrix.example.com': Uri.parse('https://matrix.example.com'),
      'matrix.example.com/': Uri.parse('https://matrix.example.com/'),
      'matrix.example.com:8443': Uri.parse('https://matrix.example.com:8443'),
      '192.168.88.253:8443': Uri.parse('https://192.168.88.253:8443'),
      '[::1]:8448': Uri.parse('https://[::1]:8448'),
      'localhost:8083': Uri.parse('https://localhost:8083'),
      'matrix.example.com:8443/': Uri.parse('https://matrix.example.com:8443/'),
      'matrix.org/path': Uri.parse('https://matrix.org/path'),
      'matrix.example.com:8443/proxy/https://bridge': Uri.parse(
        'https://matrix.example.com:8443/proxy/https://bridge',
      ),
      'https://matrix.example.com:8443': Uri.parse(
        'https://matrix.example.com:8443',
      ),
      'http://localhost:8083': Uri.parse('http://localhost:8083'),
    };

    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('parses "$input"', () {
        final uri = input.toHomeserverUri();

        expect(uri, expected);
        expect(uri.host, isNotEmpty);
      });
    }

    test('keeps the port', () {
      expect('matrix.example.com:8443'.toHomeserverUri().port, 8443);
      expect('[::1]:8448'.toHomeserverUri().port, 8448);
    });
  });
}
