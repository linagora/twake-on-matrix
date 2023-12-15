import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("getMentionsFromMessage tests", () {
    test('getMentionsFromMessage returns a list of mentions', () {
      const message = "Hello @[John Doe] and @[Jane Smith]! How are you?";
      final result = message.getMentionsFromMessage();

      expect(result, containsAll(['@[John Doe]', '@[Jane Smith]']));
      expect(result.length, equals(2));
    });

    test(
        'getMentionsFromMessage returns an empty list if no mentions are found',
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

    test('getMentionsFromMessage returns an empty list for an empty message',
        () {
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

    test(
        'getMentionsFromMessage returns an empty list if there is empty mention',
        () {
      const message = "Hello everyone! How are you? Let's meet @[]";
      final result = message.getMentionsFromMessage();

      expect(result, isEmpty);
    });
  });

  group("unMarkdownLinks tests", () {
    test('unMarkdownLinks should replace links when there is only one link',
        () {
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

      final result = markdownMessageWith2Links
          .unMarkdownLinks(unMarkdownMessageWith2Links);

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

      final result = markdownMessageWithNoLink
          .unMarkdownLinks(unMarkdownMessageWithNoLink);

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
  });

  group('String contains word tests', () {
    const String sampleString = 'Hello world';
    test('Contains word - Case insensitive', () {
      expect(sampleString.containsWord('hello'), true);
      expect(sampleString.containsWord('WORLD'), true);
    });

    test('Does not contain word - Case insensitive', () {
      expect(sampleString.containsWord('foo'), false);
      expect(sampleString.containsWord('bar'), false);
    });

    test('Contains word - Case sensitive', () {
      expect(sampleString.containsWord('Hello'), true);
      expect(sampleString.containsWord('world'), true);
    });

    test('Does not contain word - Case sensitive', () {
      expect(sampleString.containsWord('Foo'), false);
      expect(sampleString.containsWord('BAR'), false);
    });

    test('Empty string', () {
      expect(''.containsWord('word'), false);
    });
  });

  group('Highlight text in HTML tests', () {
    test('Highlight text in HTML', () {
      const inputHtml = '<p>Đây là một đoạn văn bản mẫu.</p>';
      const targetText = 'đoạn văn bản';
      const expectedOutput =
          '<p>Đây là một <span data-mx-bg-color=gold>đoạn văn bản</span> mẫu.</p>';

      expect(inputHtml.htmlHighlightText(targetText), expectedOutput);
    });

    test('Highlight text in HTML with mixed case', () {
      const inputHtml = '<p>Đây là một đoạn văn bản mẫu.</p>';
      const targetText = 'Đoạn Văn Bản';
      const expectedOutput =
          '<p>Đây là một <span data-mx-bg-color=gold>đoạn văn bản</span> mẫu.</p>';

      expect(inputHtml.htmlHighlightText(targetText), expectedOutput);
    });

    test('Highlight HTML tag in HTML', () {
      const inputHtml = '<p>Đây là một <span>đoạn văn bản</span> mẫu.</p>';
      const targetText = '<span>';
      const expectedOutput = '<p>Đây là một <span>đoạn văn bản</span> mẫu.</p>';

      expect(inputHtml.htmlHighlightText(targetText), expectedOutput);
    });

    test('Highlight HTML attribute in HTML', () {
      const inputHtml = '<a href="https://example.com">Link</a>';
      const targetText = 'href';
      const expectedOutput = '<a href="https://example.com">Link</a>';

      expect(inputHtml.htmlHighlightText(targetText), expectedOutput);
    });

    test('Highlight text in HTML with multiple occurrences', () {
      const inputHtml =
          '<p>Đây là một đoạn văn bản mẫu.</p><p>Đây là một đoạn văn bản mẫu.</p>';
      const targetText = 'đoạn văn bản';
      const expectedOutput =
          '<p>Đây là một <span data-mx-bg-color=gold>đoạn văn bản</span> mẫu.</p><p>Đây là một <span data-mx-bg-color=gold>đoạn văn bản</span> mẫu.</p>';

      expect(inputHtml.htmlHighlightText(targetText), expectedOutput);
    });

    test('HTML without opening tag', () {
      const String inputHtml = 'Đây là một đoạn văn bản mẫu.</p>';
      const String targetText = 'đoạn văn bản';
      const String expectedOutput =
          'Đây là một <span data-mx-bg-color=gold>đoạn văn bản</span> mẫu.</p>';

      expect(inputHtml.htmlHighlightText(targetText), expectedOutput);
    });
  });

  group("substringToHighlight tests", () {
    test('substringToHighlight returns the correct substring', () {
      const text = "Hello, world!";
      const highlightText = "world";
      final result = text.substringToHighlight(highlightText);

      expect(result, equals("...world!"));
    });

    test('substringToHighlight returns the correct substring with prefix', () {
      const text = "Hello, world!";
      const highlightText = "world";
      const prefixLength = 3;
      final result =
          text.substringToHighlight(highlightText, prefixLength: prefixLength);

      expect(result, equals("...o, world!"));
    });

    test(
        'substringToHighlight returns an empty string if highlightText is empty',
        () {
      const text = "Hello, world!";
      const highlightText = "";
      final result = text.substringToHighlight(highlightText);

      expect(result, equals("Hello, world!"));
    });

    test(
        'substringToHighlight returns an empty string if highlightText is not found',
        () {
      const text = "Hello, world!";
      const highlightText = "foo";
      final result = text.substringToHighlight(highlightText);

      expect(result, equals("Hello, world!"));
    });

    test(
        'substringToHighlight returns the full string if highlightText is the same as text',
        () {
      const text = "Hello, world!";
      const highlightText = "Hello, world!";
      final result = text.substringToHighlight(highlightText);

      expect(result, equals(text));
    });

    test(
        'substringToHighlight returns second line if text have multi short line',
        () {
      const text = "First\nSecond\nThird";
      const highlightText = "Second";
      final result = text.substringToHighlight(highlightText, prefixLength: 3);

      expect(result, equals('...Second\nThird'));
    });

    test('substringToHighlight returns last line if text have multi short line',
        () {
      const text = "First\nSecond\nThird";
      const highlightText = "Third";
      final result = text.substringToHighlight(highlightText, prefixLength: 3);

      expect(result, equals('...Third'));
    });

    test(
        'substringToHighlight returns last line if text have multi short line and long prefix length',
        () {
      const text = "First\nSecond\nThird";
      const highlightText = "Third";
      final result = text.substringToHighlight(highlightText, prefixLength: 20);

      expect(result, equals('...Third'));
    });
  });

  group('msisdnSanitizer tests', () {
    test('msisdnSanitizer returns the correct msisdn with leading plus', () {
      final result = '+08030000000'.msisdnSanitizer();
      expect(result, equals('08030000000'));
    });

    test('msisdnSanitizer returns the correct msisdn without leading plus', () {
      final result = '08030000000'.msisdnSanitizer();
      expect(result, equals('08030000000'));
    });

    test('msisdnSanitizer returns the correct msisdn with special characters',
        () {
      final result = '+234803000#!*()%,^&0000'.msisdnSanitizer();
      expect(result, equals('2348030000000'));
    });

    test('msisdnSanitizer returns the correct msisdn with letters', () {
      final result = '+234803000kddskdskf0000'.msisdnSanitizer();
      expect(result, equals('2348030000000'));
    });

    test('msisdnSanitizer returns the correct msisdn with spaces', () {
      final result = '+234000000080 3000 00 00'.msisdnSanitizer();
      expect(result, equals('23400000008030000000'));
    });

    test('msisdnSanitizer returns the correct msisdn with long phone code', () {
      final result = '+234234234234 80 3000 00 00'.msisdnSanitizer();
      expect(result, equals('2342342342348030000000'));
    });

    test('msisdnSanitizer returns the correct msisdn with parentheses', () {
      final result = '(+84) 366 6769 439'.msisdnSanitizer();
      expect(result, equals('843666769439'));
    });

    test('msisdnSanitizer returns the correct msisdn with hyphens', () {
      final result = '+84-366-769-439'.msisdnSanitizer();
      expect(result, equals('84366769439'));
    });

    test(
        'msisdnSanitizer returns the correct msisdn with hyphens and no spaces',
        () {
      final result = '+84-3667-69439'.msisdnSanitizer();
      expect(result, equals('84366769439'));
    });
  });

  group('urlSafeBase64 tests', () {
    test('urlSafeBase64 replaces + with -', () {
      const input = 'a+b+c';
      const expectedOutput = 'a-b-c';
      expect(input.urlSafeBase64, equals(expectedOutput));
    });

    test('urlSafeBase64 replaces / with _', () {
      const input = 'a/b/c';
      const expectedOutput = 'a_b_c';
      expect(input.urlSafeBase64, equals(expectedOutput));
    });

    test('urlSafeBase64 does not modify string without + or /', () {
      const input = 'abc123';
      const expectedOutput = 'abc123';
      expect(input.urlSafeBase64, equals(expectedOutput));
    });
  });

  test('sha256Hash returns the correct SHA-256 hash', () {
    const input = 'Hello, world!';
    const expectedOutput =
        '315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3';
    final result = input.sha256Hash;
    expect(result, equals(expectedOutput));
  });
}
