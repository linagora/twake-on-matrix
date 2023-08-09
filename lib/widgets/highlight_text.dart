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
    final spans = buildTextSpans();
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }

  List<TextSpan> buildTextSpans() {
    if ((searchWord?.isEmpty ?? true) || text.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    // Split the text into parts by the search word and create a TextSpan for
    // each part. The search word is not case sensitive.
    final List<TextSpan> spans = [];
    text.splitMapJoin(
      RegExp(searchWord!, caseSensitive: false),
      onMatch: (Match match) {
        spans.add(buildHighlightSpan(match.group(0)!));
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(buildNormalSpan(nonMatch));
        return '';
      },
    );
    return spans;
  }

  TextSpan buildHighlightSpan(String content) {
    if (highlightStyle == null) {
      return TextSpan(
        text: content,
        style: style!.copyWith(
          color: Colors.amber[900],
        ),
      );
    }

    return TextSpan(text: content, style: highlightStyle);
  }

  TextSpan buildNormalSpan(String content) {
    return TextSpan(text: content, style: style);
  }
}
