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

    expect(
      result,
      containsAll(['@[John Doe]', '@[Jane Smith]', '@[Bob Johnson]']),
    );
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

  test('unMarkdownLinks should replace links when there is only one link', () {
    const unMarkdownMessageWithOnlyLink =
        "https://superman.com/this-is-a-*superman*-link";
    const markdownMessageWithOnlyLink =
        "https://superman.com/this-is-a-<em>superman</em>-link";

    final result = markdownMessageWithOnlyLink
        .unMarkdownLinks(unMarkdownMessageWithOnlyLink);

    expect(result, equals(unMarkdownMessageWithOnlyLink));
  });

  test('unMarkdownLinks should replace links when there are multiple links',
      () {
    const unMarkdownMessageWith2Links =
        "https://superman.com/this-is-a-*superman*-link https://batman.com/this-is-a-*batman*-link";
    const markdownMessageWith2Links =
        "https://superman.com/this-is-a-<em>superman</em>-link https://batman.com/this-is-a-<em>batman</em>-link";

    final result =
        markdownMessageWith2Links.unMarkdownLinks(unMarkdownMessageWith2Links);

    expect(result, equals(unMarkdownMessageWith2Links));
  });

  test('unMarkdownLinks should replace links when there are links and text',
      () {
    const unMarkdownMessageWithLinksAndTexts =
        "is this serious https://superman.com/this-is-a-*superman*-link hello guys https://batman.com/this-is-a-*batman*-link";
    const markdownMessageWithLinksAndTexts =
        "is this serious https://superman.com/this-is-a-<em>superman</em>-link hello guys https://batman.com/this-is-a-<em>batman</em>-link";

    final result = markdownMessageWithLinksAndTexts
        .unMarkdownLinks(unMarkdownMessageWithLinksAndTexts);
    expect(result, equals(unMarkdownMessageWithLinksAndTexts));
  });

  test(
      'unMarkdownLinks should replace links when there is link starting with text',
      () {
    const unMarkdownMessageWithLinkStartingWithText =
        "is this serious https://superman.com/this-is-a-*superman*-link";
    const markdownMessageWithLinkStartingWithText =
        "is this serious https://superman.com/this-is-a-<em>superman</em>-link";

    final result = markdownMessageWithLinkStartingWithText
        .unMarkdownLinks(unMarkdownMessageWithLinkStartingWithText);
    expect(result, equals(unMarkdownMessageWithLinkStartingWithText));
  });

  test('unMarkdownLinks should not replace links when the link is not valid',
      () {
    const unMarkdownMessageWithUnvalidLink =
        "is this serious-https://superman.com/this-is-a-<em>superman</em>-link";
    const markdownMessageWithUnvalidLink =
        "is this serious-https://superman.com/this-is-a-<em>superman</em>-link";

    final result = markdownMessageWithUnvalidLink
        .unMarkdownLinks(unMarkdownMessageWithUnvalidLink);
    expect(result, equals(unMarkdownMessageWithUnvalidLink));
  });

  test('unMarkdownLinks should return formatted text when there is no link',
      () {
    const unMarkdownMessageWithNoLink = "hello guys";
    const markdownMessageWithNoLink = "hello guys";

    final result =
        markdownMessageWithNoLink.unMarkdownLinks(unMarkdownMessageWithNoLink);

    expect(result, equals(unMarkdownMessageWithNoLink));
  });

  test(
      'unMarkdownLinks should replace links when there is link ending with text',
      () {
    const unMarkdownMessageWithLinkEndingWithText =
        "https://superman.com/this-is-a-*superman*-link hello guys";
    const markdownMessageWithLinkEndingWithText =
        "https://superman.com/this-is-a-<em>superman</em>-link hello guys";

    final result = markdownMessageWithLinkEndingWithText
        .unMarkdownLinks(unMarkdownMessageWithLinkEndingWithText);
    expect(result, equals(unMarkdownMessageWithLinkEndingWithText));
  });

  test(
      'unMarkdownLinks should replace links when there is link ending with incomplete markdown',
      () {
    const unMarkdownMessageWithIncompleteMarkdownLink =
        "https://superman.com/this-is-a-*supe hello guys";
    const markdownMessageWithIncompleteMarkdownLink =
        "https://superman.com/this-is-a-<em>supe hello guys";

    final result = markdownMessageWithIncompleteMarkdownLink
        .unMarkdownLinks(unMarkdownMessageWithIncompleteMarkdownLink);
    expect(result, equals(unMarkdownMessageWithIncompleteMarkdownLink));
  });

  test(
      'unMarkdownLinks should replace links when there are text and unusable links',
      () {
    const unMarkdownMessageWithUnusableLinks =
        "https://superman.com/this-is-a-*superman*-link hello guys https://bat";
    const markdownMessageWithUnusableLinks =
        "https://superman.com/this-is-a-<em>superman</em>-link hello guys https://bat";

    final result = markdownMessageWithUnusableLinks
        .unMarkdownLinks(unMarkdownMessageWithUnusableLinks);
    expect(result, equals(unMarkdownMessageWithUnusableLinks));
  });

  test(
      'unMarkdownLinks should replace links when there are markdown and unmarkdown links',
      () {
    const unMarkdownMessageWithMarkdownAndUnMarkdownLinks =
        "https://superman.com/this-is-a-*superman*-link hello guys https://batman.com/this-";
    const markdownMessageWithMarkdownAndUnMarkdownLinks =
        "https://superman.com/this-is-a-<em>superman</em>-link hello guys https://batman.com/this-";

    final result = markdownMessageWithMarkdownAndUnMarkdownLinks
        .unMarkdownLinks(unMarkdownMessageWithMarkdownAndUnMarkdownLinks);
    expect(result, equals(unMarkdownMessageWithMarkdownAndUnMarkdownLinks));
  });

  test(
      'unMarkdownLinks should return formatted link when the unformatted text has no link',
      () {
    const messageWithNoLinkUnMarkdowned = "hello guys";
    const messageWithNoLinkMarkdowned =
        "hello guys https://superman.com/this-is-a-*superman*-link";

    final result = messageWithNoLinkMarkdowned
        .unMarkdownLinks(messageWithNoLinkUnMarkdowned);

    expect(result, equals(messageWithNoLinkMarkdowned));
  });
}
