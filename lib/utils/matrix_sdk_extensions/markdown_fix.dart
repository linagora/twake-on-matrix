import 'package:html_unescape/html_unescape.dart';

final _codeContentPattern = RegExp(
  r'(<code[^>]*>)(.*?)(</code>)',
  dotAll: true,
);

final _doubleEncodedEntity = RegExp(r'&amp;(#?[a-zA-Z0-9]+;)');

// Bounded per ADR 0033: an href up to the 2048-char URL limit, anchor text
// up to 1000 chars.
final _anchorPattern = RegExp(r'<a href="([^"]{0,2048})">([^<]{0,1000})</a>');

final _percentEscape = RegExp('%[0-9A-Fa-f]{2}');

/// Fixes the `href` of bare-URL links that markdown encoded twice.
///
/// package:markdown builds the `href` of a GitHub-flavored autolink with
/// `Uri.encodeFull`, which also encodes `%`: `%3A` becomes `%253A` and the
/// link no longer opens its target. Only anchors whose `href` is exactly
/// that encoding of their text (with `http://` added for `www.` links) are
/// rewritten, keeping existing `%XX` escapes as CommonMark does for other
/// links; every other anchor is left as it is.
///
/// [source] is the markdown the HTML came from (the event `body`). An anchor
/// whose href is written there as an explicit destination (`](href`) was
/// not an autolink and is kept, even when it matches the pattern above.
String fixDoubleEncodedAutolinks(String html, {required String source}) {
  final unescape = HtmlUnescape();
  return html.replaceAllMapped(_anchorPattern, (match) {
    final href = unescape.convert(match.group(1)!);
    if (source.contains(']($href') || source.contains('](<$href')) {
      return match.group(0)!;
    }
    final text = match.group(2)!;
    final url = unescape.convert(text);
    final destination = href == Uri.encodeFull(url)
        ? url
        : href == Uri.encodeFull('http://$url')
        ? 'http://$url'
        : null;
    if (destination == null) return match.group(0)!;
    final fixedHref = destination
        .splitMapJoin(
          _percentEscape,
          onMatch: (escape) => escape.group(0)!,
          onNonMatch: Uri.encodeFull,
        )
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;');
    return '<a href="$fixedHref">$text</a>';
  });
}

/// Fixes double-encoded HTML entities inside `<code>` elements.
///
/// The markdown pipeline escapes `<` → `&lt;`, then the code-block renderer
/// re-escapes → `&amp;lt;`. This collapses one layer: `&amp;lt;` → `&lt;`,
/// leaving valid single-encoded HTML for the renderer.
String fixDoubleEncodedCodeBlocks(String html) {
  return html.replaceAllMapped(_codeContentPattern, (match) {
    final openTag = match.group(1)!;
    final content = match
        .group(2)!
        .replaceAllMapped(_doubleEncodedEntity, (m) => '&${m.group(1)}');
    final closeTag = match.group(3)!;
    return '$openTag$content$closeTag';
  });
}
