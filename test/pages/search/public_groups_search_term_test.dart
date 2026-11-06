import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/search/public_groups_search_term.dart';

void main() {
  late TextEditingController textController;
  late PublicGroupsSearchTerm searchTerm;

  setUp(() {
    textController = TextEditingController();
    searchTerm = PublicGroupsSearchTerm(textController);
  });

  tearDown(() {
    searchTerm.dispose();
    textController.dispose();
  });

  test('value_whenTheTypingStops_isTheTrimmedText', () {
    fakeAsync((async) {
      // Arrange
      textController.text = ' éq';

      // Act
      async.elapse(PublicGroupsSearchTerm.debounceDuration);

      // Assert
      expect(searchTerm.value, 'éq');
    });
  });

  test('value_whileTyping_staysUntilTheTypingStops', () {
    fakeAsync((async) {
      // Arrange
      textController.text = 'éq';

      // Act
      async.elapse(const Duration(milliseconds: 100));
      textController.text = 'équ';
      async.elapse(const Duration(milliseconds: 200));

      // Assert
      expect(searchTerm.value, isNull);
      async.elapse(const Duration(milliseconds: 100));
      expect(searchTerm.value, 'équ');
    });
  });

  test('value_underTwoLetters_isNullAtOnce', () {
    fakeAsync((async) {
      // Arrange
      textController.text = 'éq';
      async.elapse(PublicGroupsSearchTerm.debounceDuration);

      // Act
      textController.text = 'é ';

      // Assert
      expect(searchTerm.value, isNull);
    });
  });
}
