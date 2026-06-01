import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart' as url_launcher_link;

/// Wraps an [InlineSpan] representing a URL into a [WidgetSpan] containing
/// a [url_launcher_link.Link] so the browser renders a real `<a>` element
/// overlay on Flutter web. This gives the user native right-click context
/// menu items ("Open in new tab", "Copy link address").
InlineSpan? buildNativeLinkSpan({
  required String url,
  required InlineSpan childrenSpan,
  required TextStyle? linkStyle,
  required GestureTapDownCallback onTapDown,
}) {
  if (!kIsWeb || url.isEmpty) return null;
  final parsed = Uri.tryParse(url);
  if (parsed == null) return null;
  final uri = switch (parsed.scheme) {
    'http' || 'https' => parsed,
    '' => Uri.tryParse('https://$url'),
    _ => null,
  };
  if (uri == null) return null;
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: url_launcher_link.Link(
      uri: uri,
      target: url_launcher_link.LinkTarget.blank,
      builder: (_, __) => GestureDetector(
        onTapDown: onTapDown,
        child: Text.rich(TextSpan(style: linkStyle, children: [childrenSpan])),
      ),
    ),
  );
}
