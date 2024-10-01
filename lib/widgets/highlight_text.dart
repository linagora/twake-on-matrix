import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String? searchWord;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const HighlightText({
    super.key,
    required this.text,
    required this.searchWord,
    required this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
    this.softWrap,
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
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
