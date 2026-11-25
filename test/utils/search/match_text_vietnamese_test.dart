// Issue #3021: an ASCII query must find a Vietnamese name written with đ / Đ
// when the search ignores diacritics.
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';

const _engine = SearchEngine();
const _ignoringDiacritics = SearchOptions(diacriticSensitive: false);

void main() {
  group('matchesText vietnamese — diacriticSensitive: false', () {
    test('should find Đặng when searching dang', () {
      expect(
        _engine.matchesText(
          'dang',
          'Đặng Văn Lâm',
          options: _ignoringDiacritics,
        ),
        isTrue,
      );
    });

    test('should find Đỗ when searching DO', () {
      expect(
        _engine.matchesText('DO', 'Đỗ Thị Hà', options: _ignoringDiacritics),
        isTrue,
      );
    });

    test('should find đ inside a word when searching d', () {
      expect(
        _engine.matchesText('dong', 'Hà Đông', options: _ignoringDiacritics),
        isTrue,
      );
    });

    test('should find a name typed with đ', () {
      expect(
        _engine.matchesText(
          'Đặng',
          'Đặng Văn Lâm',
          options: _ignoringDiacritics,
        ),
        isTrue,
      );
    });
  });

  group('matchesText vietnamese — default options', () {
    test('should keep đ distinct from d', () {
      expect(_engine.matchesText('dang', 'Đặng Văn Lâm'), isFalse);
    });
  });
}
