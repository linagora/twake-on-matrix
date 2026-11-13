import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/policy/drive_links_message_policy.dart';

DrivePickedFile _file(String name, String? url) => DrivePickedFile(
  id: name,
  name: name,
  size: 1,
  shareUri: url == null ? null : Uri.parse(url),
);

void main() {
  const policy = DriveLinksMessagePolicy(requireHttps: true);

  group('DriveLinksMessagePolicy.format', () {
    test('one file gives one Markdown link', () {
      final text = policy.format([_file('a.pdf', 'https://x.example/s/1')]);

      expect(text, '[a.pdf](https://x.example/s/1)');
    });

    test('three files give three lines, in order', () {
      final text = policy.format([
        _file('a', 'https://x.example/s/1'),
        _file('b', 'https://x.example/s/2'),
        _file('c', 'https://x.example/s/3'),
      ]);

      expect(text.split('\n'), [
        '[a](https://x.example/s/1)',
        '[b](https://x.example/s/2)',
        '[c](https://x.example/s/3)',
      ]);
    });

    test('brackets in a name are dropped so the label cannot end early', () {
      final text = policy.format([
        _file('re[port].pdf', 'https://x.example/s'),
      ]);

      expect(text, '[report.pdf](https://x.example/s)');
    });

    test(
      'a backslash in a name is dropped so it cannot escape the bracket',
      () {
        final text = policy.format([_file(r'report\', 'https://x.example/s')]);

        expect(text, '[report](https://x.example/s)');
      },
    );

    test(
      'a line break in a name becomes a space so the link stays on one line',
      () {
        final text = policy.format([
          _file('re\nport\r\n.pdf', 'https://x.example/s'),
        ]);

        expect(text, '[re port .pdf](https://x.example/s)');
      },
    );

    test('a name too long for one message is cut so the link fits', () {
      final text = policy.format([_file('n' * 5000, 'https://x.example/s')]);

      expect(text.length, DriveLinksMessagePolicy.maxMessageLength);
      expect(text, endsWith('](https://x.example/s)'));
    });

    test('a link whose URL alone is too long is left out', () {
      final text = policy.format([
        _file('a', 'https://x.example/${'p' * 5000}'),
        _file('b', 'https://x.example/s'),
      ]);

      expect(text, '[b](https://x.example/s)');
    });

    test('parentheses in a URL are encoded so the link cannot end early', () {
      final text = policy.format([_file('a', 'https://x.example/s(1)')]);

      expect(text, '[a](https://x.example/s%281%29)');
    });

    test('a file with no link is left out', () {
      final text = policy.format([
        _file('a', null),
        _file('b', 'https://x.example/s/2'),
      ]);

      expect(text, '[b](https://x.example/s/2)');
    });

    test('an empty list gives an empty text', () {
      expect(policy.format(const []), isEmpty);
    });

    test('nothing with a usable link gives an empty text', () {
      expect(policy.format([_file('a', null)]), isEmpty);
    });

    test('http and other schemes are left out when https is required', () {
      final text = policy.format([
        _file('a', 'http://x.example/s'),
        _file('b', 'javascript:alert(1)'),
        _file('c', 'https://x.example/s/3'),
      ]);

      expect(text, '[c](https://x.example/s/3)');
    });

    test('http is kept when https is not required (debug)', () {
      const debug = DriveLinksMessagePolicy(requireHttps: false);

      final text = debug.format([_file('a', 'http://x.example/s')]);

      expect(text, '[a](http://x.example/s)');
    });

    test('a scheme other than http(s) is left out even in debug', () {
      const debug = DriveLinksMessagePolicy(requireHttps: false);

      expect(debug.format([_file('a', 'ftp://x.example/s')]), isEmpty);
    });
  });

  group('DriveLinksMessagePolicy.split', () {
    const policy = DriveLinksMessagePolicy(requireHttps: true);

    test('keeps a short text as one message', () {
      expect(policy.split('a\nb'), ['a\nb']);
    });

    test('cuts between lines and never inside a link', () {
      final lines = [for (var i = 0; i < 6; i++) 'link$i' * 3];

      final messages = policy.split(lines.join('\n'), maxLength: 40);

      expect(messages.length, greaterThan(1));
      expect(messages.every((m) => m.length <= 40), isTrue);
      expect(messages.join('\n').split('\n'), lines);
    });

    test('keeps a single line longer than the limit whole', () {
      final line = 'x' * 50;

      expect(policy.split('a\n$line\nb', maxLength: 40), ['a', line, 'b']);
    });

    test('is empty for an empty text', () {
      expect(policy.split(''), isEmpty);
    });
  });
}
