import 'package:html_unescape/html_unescape.dart';

final _codeContentPattern = RegExp(
  r'(<code[^>]*>)(.*?)(</code>)',
  dotAll: true,
);

/// Fixes double-encoded HTML entities inside `<code>` elements.
/// See: https://github.com/linagora/twake-on-matrix/issues/3089
String fixDoubleEncodedCodeBlocks(String html) {
  final unescape = HtmlUnescape();
  return html.replaceAllMapped(_codeContentPattern, (match) {
    final openTag = match.group(1)!;
    var content = match.group(2)!;
    final closeTag = match.group(3)!;
    // Two passes: &amp;lt; → &lt; → <
    content = unescape.convert(content);
    content = unescape.convert(content);
    return '$openTag$content$closeTag';
  });
}
