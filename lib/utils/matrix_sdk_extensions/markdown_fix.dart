final _codeContentPattern = RegExp(
  r'(<code[^>]*>)(.*?)(</code>)',
  dotAll: true,
);

final _doubleEncodedEntity = RegExp(r'&amp;(#?[a-zA-Z0-9]+;)');

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
