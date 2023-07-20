import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getShortcutNameForAvatar', () {
    // Group 1: Returns 1 character
    group('when input has only one word', () {
      test('should return the first character', () {
        expect('John'.getShortcutNameForAvatar(), 'J');
        expect('Apple'.getShortcutNameForAvatar(), 'A');
      });

      test('should return "@" if input string is empty', () {
        expect(''.getShortcutNameForAvatar(), '@');
      });

      test('should return "@" if input has only whitespace characters', () {
        expect('   '.getShortcutNameForAvatar(), '@');
        expect('\t\t\t'.getShortcutNameForAvatar(), '@');
      });

      test(
          'should return the first non-ASCII character if input has non-ASCII characters',
          () {
        expect('Æblegrød'.getShortcutNameForAvatar(), 'Æ');
      });

      test('should return the input character in upper case', () {
        expect('j'.getShortcutNameForAvatar(), 'J');
        expect('a'.getShortcutNameForAvatar(), 'A');
        expect('æ'.getShortcutNameForAvatar(), 'Æ');
      });

      test(
          'should ignore leading/trailing spaces and return "@" if there are no words',
          () {
        expect('   '.getShortcutNameForAvatar(), '@');
        expect('\t\t\t'.getShortcutNameForAvatar(), '@');
        expect('  \t\n   \r '.getShortcutNameForAvatar(), '@');
      });
    });

    // Group 2: Returns 2 characters
    group('when input has multiple words', () {
      test('should return the first characters of the first and last words',
          () {
        expect('John Doe'.getShortcutNameForAvatar(), 'JD');
        expect('Apple Pie'.getShortcutNameForAvatar(), 'AP');
        expect('Foo Bar Baz'.getShortcutNameForAvatar(), 'FB');
      });

      test(
          'should return the first characters of the first and last words in upper case',
          () {
        expect('john doe'.getShortcutNameForAvatar(), 'JD');
        expect('apple pie'.getShortcutNameForAvatar(), 'AP');
        expect('foo bar baz'.getShortcutNameForAvatar(), 'FB');
      });

      test(
          'should return the first characters of the first and second words in upper case',
          () {
        expect('Đỗ Quang Khải'.getShortcutNameForAvatar(), 'ĐQ');
        expect('John Paul Jones'.getShortcutNameForAvatar(), 'JP');
      });

      test(
          'should ignore leading/trailing spaces and return the first characters of the first and last words',
          () {
        expect('  John Doe  '.getShortcutNameForAvatar(), 'JD');
        expect('\tApple Pie\t'.getShortcutNameForAvatar(), 'AP');
        expect(' Foo  Bar  Baz '.getShortcutNameForAvatar(), 'FB');
      });

      test('should handle special characters', () {
        expect('John D. Rockefeller'.getShortcutNameForAvatar(), 'JD');
        expect('12345 One Two Three'.getShortcutNameForAvatar(), '1O');
        expect('\$%&*!@# A B C'.getShortcutNameForAvatar(), '\$A');
      });
    });
  });
}
