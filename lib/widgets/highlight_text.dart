import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String? searchWord;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  const HighlightText({
    super.key,
    required this.text,
    required this.searchWord,
    required this.style,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    final actualHighlightStyle = highlightStyle ??
        style?.copyWith(
          color: Colors.amber[900],
        );
    final spans = text.buildHighlightTextSpans(
      searchWord ?? '',
      style: style,
      highlightStyle: actualHighlightStyle,
    );
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}
