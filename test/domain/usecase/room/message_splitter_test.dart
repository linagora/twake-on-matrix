import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/usecase/room/message_splitter.dart';

void main() {
  group('MessageSplitter', () {
    const MessageSplitter splitter = MessageSplitter(maxLength: 5);

    test(
      'should return the text unchanged when it is shorter than the limit',
      () {
        // Arrange
        const String text = 'abc';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abc']));
      },
    );

    test(
      'should return a single part when the text length equals the limit',
      () {
        // Arrange
        const String text = 'abcde';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abcde']));
      },
    );

    test(
      'should return a full part and the last character when the text exceeds the limit by one',
      () {
        // Arrange
        const String text = 'abcdef';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abcde', 'f']));
      },
    );

    test(
      'should return only full parts when the text length is a multiple of the limit',
      () {
        // Arrange
        const String text = 'abcdefghij';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abcde', 'fghij']));
      },
    );

    test(
      'should fill every part but the last to the limit when the text is long',
      () {
        // Arrange
        const String text = 'abcdefghijkl';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abcde', 'fghij', 'kl']));
      },
    );

    test('should return a single empty part when the text is empty', () {
      // Arrange
      const String text = '';

      // Act
      final List<String> parts = splitter.split(text);

      // Assert
      expect(parts, equals(['']));
    });

    test(
      'should move an emoji to the next part when the cut falls inside it',
      () {
        // Arrange: the emoji is two code units.
        const String text = 'abcd😀';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abcd', '😀']));
      },
    );

    test('should keep a flag whole when the cut falls inside it', () {
      // Arrange: a flag is four code units.
      const String text = 'abc🇫🇷';

      // Act
      final List<String> parts = splitter.split(text);

      // Assert
      expect(parts, equals(['abc', '🇫🇷']));
    });

    test(
      'should keep a grapheme whole when the cut falls before its combining mark',
      () {
        // Arrange: "e" plus a combining accent is one grapheme.
        const String text = 'abcde\u0301';

        // Act
        final List<String> parts = splitter.split(text);

        // Assert
        expect(parts, equals(['abcd', 'e\u0301']));
      },
    );

    test(
      'should keep a grapheme longer than the limit whole in its own part',
      () {
        // Arrange: the family emoji is eleven code units.
        const MessageSplitter tinySplitter = MessageSplitter(maxLength: 2);
        const String text = 'ab👨‍👩‍👧‍👦c';

        // Act
        final List<String> parts = tinySplitter.split(text);

        // Assert
        expect(parts, equals(['ab', '👨‍👩‍👧‍👦', 'c']));
      },
    );

    test(
      'should restore the original text and respect the limit when no grapheme exceeds it',
      () {
        // Arrange
        const List<String> texts = [
          'abcdefghijkl',
          'ab🇫🇷cd😀e\u0301fgh😀ij',
          'line one\nline two\n\nline four',
        ];

        for (final String text in texts) {
          // Act
          final List<String> parts = splitter.split(text);

          // Assert
          expect(parts.join(), equals(text));
          expect(
            parts.every((part) => part.length <= splitter.maxLength),
            isTrue,
          );
        }
      },
    );

    test('should throw an assertion error when maxLength is zero', () {
      // Act
      MessageSplitter build() => MessageSplitter(maxLength: 0);

      // Assert
      expect(build, throwsAssertionError);
    });
  });
}
