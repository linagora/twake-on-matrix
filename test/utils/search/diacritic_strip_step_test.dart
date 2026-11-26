// Tests DiacriticStripStep directly: ASCII fast path and accented inputs.
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/search/steps/diacritic_strip_step.dart';

void main() {
  for (final decomposition in UnicodeDecomposition.values) {
    group('DiacriticStripStep ($decomposition)', () {
      final step = DiacriticStripStep(decomposition: decomposition);

      test('should return ASCII input unchanged, preserving case', () {
        expect(step.normalize('Hello, World! 123'), 'Hello, World! 123');
      });

      test('should return empty input unchanged', () {
        expect(step.normalize(''), '');
      });

      test('should strip Latin diacritics', () {
        expect(step.normalize('Élie Français'), 'Elie Francais');
      });

      test('should strip Vietnamese diacritics from mixed input', () {
        expect(step.normalize('Tiếng Việt abc'), 'Tieng Viet abc');
      });

      // Issue #3021: đ / Đ are letters of their own, not d plus a mark, so
      // decomposition leaves them as they are.
      test('should map Vietnamese đ and Đ to d and D', () {
        expect(step.normalize('Đặng Đỗ Hà Đông đi'), 'Dang Do Ha Dong di');
      });
    });
  }
}
