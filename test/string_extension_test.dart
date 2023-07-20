import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getMentionsFromMessage returns a list of mentions', () {
    const message = "Hello @[John Doe] and @[Jane Smith]! How are you?";
    final result = message.getMentionsFromMessage();

    expect(result, containsAll(['@[John Doe]', '@[Jane Smith]']));
    expect(result.length, equals(2));
  });

  test('getMentionsFromMessage returns an empty list if no mentions are found',
      () {
    const message = "Hello everyone! How are you?";
    final result = message.getMentionsFromMessage();

    expect(result, isEmpty);
  });

  test('getMentionsFromMessage handles multiple mentions in a message', () {
    const message = "Hello @[John Doe], @[Jane Smith], and @[Bob Johnson]!";
    final result = message.getMentionsFromMessage();

    expect(result,
        containsAll(['@[John Doe]', '@[Jane Smith]', '@[Bob Johnson]']));
    expect(result.length, equals(3));
  });

  test('getMentionsFromMessage returns an empty list for an empty message', () {
    const message = "";
    final result = message.getMentionsFromMessage();

    expect(result, isEmpty);
  });

  test(
      'getMentionsFromMessage returns an empty list if no mentions are found with @ content',
      () {
    const message = "Hello everyone! How are you? Let's meet @ 5pm.";
    final result = message.getMentionsFromMessage();

    expect(result, isEmpty);
  });

  test('getMentionsFromMessage returns an empty list if there is empty mention',
      () {
    const message = "Hello everyone! How are you? Let's meet @[]";
    final result = message.getMentionsFromMessage();

    expect(result, isEmpty);
  });
}
