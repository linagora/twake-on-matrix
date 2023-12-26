import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:fluffychat/utils/string_extension.dart';

class TwakeHtmlParser {
  static const _matrixToScheme = "https://matrix.to/#/";
  static const _matrixScheme = "matrix:";

  static const _supportedBlockElements = <String>{
    'table',
    'thead',
    'tbody',
    'tfoot',
    'th',
    'td',
    'caption',
    'ul',
    'ol',
    'li',
    'div',
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'pre',
    'mx-reply',
    'blockquote',
    'hr',
    'details',
    'summary',
  };

  static RegExp regexpPill = RegExp(r'^[@#!+][^:]+:[^\/]+$');

  static RegExp regexpMatch = RegExp(r'^matrix:(r|roomid|u)\/([^\/]+)$');

  static bool isContentHasPill(String content) {
    final renderHtml = content.unMarkdownLinks(content).replaceAll(
          RegExp(
            '<mx-reply>.*</mx-reply>',
            caseSensitive: false,
            multiLine: false,
            dotAll: true,
          ),
          '',
        );
    final eventParser = parser.parseFragment(renderHtml);
    for (final node in eventParser.nodes) {
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();
        if (_supportedBlockElements.contains(tag)) {
          return false;
        }
        if (tag == 'a') return true;
      }
    }
    return false;
  }

  static String getContentHasPill(String content) {
    String pill = '';
    final renderHtml = content.unMarkdownLinks(content).replaceAll(
          RegExp(
            '<mx-reply>.*</mx-reply>',
            caseSensitive: false,
            multiLine: false,
            dotAll: true,
          ),
          '',
        );
    final eventParser = parser.parseFragment(renderHtml);
    for (final node in eventParser.nodes) {
      if (node is dom.Text) {
        pill += node.text;
      }
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();
        if (_supportedBlockElements.contains(tag)) {
          return content;
        }
        if (tag != 'a') return content;
        final url = node.attributes['href'];
        final urlLower = url?.toLowerCase();
        if (url != null &&
            urlLower != null &&
            (urlLower.startsWith(_matrixScheme) ||
                urlLower.startsWith(_matrixToScheme))) {
          // this might be a pill!
          var isPill = true;
          var identifier = url;
          if (urlLower.startsWith(_matrixToScheme)) {
            final urlPart =
                url.substring(_matrixToScheme.length).split('?').first;
            try {
              identifier = Uri.decodeComponent(urlPart);
            } catch (_) {
              identifier = urlPart;
            }
            isPill = regexpPill.firstMatch(identifier) != null;
          } else {
            final match = regexpMatch
                .firstMatch(urlLower.split('?').first.split('#').first);
            isPill = match != null && match.group(2) != null;
            if (isPill) {
              final sigil = {
                'r': '#',
                'roomid': '!',
                'u': '@',
              }[match.group(1)];
              if (sigil == null) {
                isPill = false;
              } else {
                identifier = sigil + match.group(2)!;
              }
            }
          }
          if (isPill) {
            pill += identifier.substring(0, identifier.indexOf(':'));
          } else {
            return content;
          }
        } else {
          return content;
        }
      }
    }

    return pill;
  }
}
