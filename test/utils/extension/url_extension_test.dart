import 'package:fluffychat/utils/extension/url_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isFilenameUrl', () {
    group('GIVEN url is null\n', () {
      test('THEN returns false', () {
        expect(isFilenameUrl(null), isFalse);
      });
    });

    group('GIVEN url has explicit scheme\n', () {
      test('WHEN https scheme'
          'THEN returns false', () {
        expect(isFilenameUrl('https://example.com/test.md'), isFalse);
      });

      test('WHEN http scheme'
          'THEN returns false', () {
        expect(isFilenameUrl('http://example.com/test.md'), isFalse);
      });

      test('WHEN https scheme with no path'
          'THEN returns false', () {
        expect(isFilenameUrl('https://test.md'), isFalse);
      });
    });

    group('GIVEN url is a bare domain (no scheme)\n', () {
      test('WHEN .com domain'
          'THEN returns false', () {
        expect(isFilenameUrl('google.com'), isFalse);
      });

      test('WHEN .io domain'
          'THEN returns false', () {
        expect(isFilenameUrl('github.io'), isFalse);
      });

      test('WHEN .org domain'
          'THEN returns false', () {
        expect(isFilenameUrl('wikipedia.org'), isFalse);
      });

      test('WHEN bare domain with path'
          'THEN returns false', () {
        expect(isFilenameUrl('example.com/page'), isFalse);
      });
    });

    group(
      'GIVEN url looks like a filename (no scheme, single dot, known extension)\n',
      () {
        test('WHEN .md extension (markdown)'
            'THEN returns true', () {
          expect(isFilenameUrl('test.md'), isTrue);
        });

        test('WHEN .pdf extension'
            'THEN returns true', () {
          expect(isFilenameUrl('document.pdf'), isTrue);
        });

        test('WHEN .xlsx extension'
            'THEN returns true', () {
          expect(isFilenameUrl('report.xlsx'), isTrue);
        });

        test('WHEN .zip extension'
            'THEN returns true', () {
          expect(isFilenameUrl('archive.zip'), isTrue);
        });

        test('WHEN .png extension'
            'THEN returns true', () {
          expect(isFilenameUrl('image.png'), isTrue);
        });

        test('WHEN .dart extension'
            'THEN returns true', () {
          expect(isFilenameUrl('main.dart'), isTrue);
        });

        test('WHEN .py extension'
            'THEN returns true', () {
          expect(isFilenameUrl('script.py'), isTrue);
        });

        test('WHEN .mp4 extension'
            'THEN returns true', () {
          expect(isFilenameUrl('video.mp4'), isTrue);
        });

        test('WHEN extension is uppercase'
            'THEN returns true (case-insensitive)', () {
          expect(isFilenameUrl('TEST.MD'), isTrue);
        });

        test('WHEN extension is mixed case'
            'THEN returns true (case-insensitive)', () {
          expect(isFilenameUrl('Report.Pdf'), isTrue);
        });

        test('WHEN multi-dot filename'
            'THEN returns true', () {
          expect(isFilenameUrl('my.report.pdf'), isTrue);
        });

        test('WHEN multi-dot filename with version'
            'THEN returns true', () {
          expect(isFilenameUrl('v1.0.zip'), isTrue);
        });

        test('WHEN multi-dot compound extension'
            'THEN returns true', () {
          expect(isFilenameUrl('archive.tar.gz'), isTrue);
        });

        test('WHEN multi-dot with markdown extension'
            'THEN returns true', () {
          expect(isFilenameUrl('sub.test.md'), isTrue);
        });
      },
    );

    group('GIVEN url looks like filename but has URL structure\n', () {
      test('WHEN has path separator after extension'
          'THEN returns false', () {
        expect(isFilenameUrl('test.md/path'), isFalse);
      });

      test('WHEN has query string'
          'THEN returns false', () {
        expect(isFilenameUrl('test.md?query=1'), isFalse);
      });

      test('WHEN has fragment'
          'THEN returns false', () {
        expect(isFilenameUrl('test.md#section'), isFalse);
      });
    });

    group('GIVEN url has no dot\n', () {
      test('THEN returns false', () {
        expect(isFilenameUrl('noextension'), isFalse);
      });
    });

    group('GIVEN url has unknown extension\n', () {
      test('WHEN extension not in file extension list'
          'THEN returns false', () {
        expect(isFilenameUrl('test.xyz123'), isFalse);
      });
    });

    group('GIVEN empty string\n', () {
      test('THEN returns false', () {
        expect(isFilenameUrl(''), isFalse);
      });
    });
  });
}
