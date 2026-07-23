import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String? searchWord;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final SearchOptions? options;

  const HighlightText({
    super.key,
    required this.text,
    required this.searchWord,
    required this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.options,
  });

  static const _defaultOptions = SearchOptions(diacriticSensitive: false);

  @override
  Widget build(BuildContext context) {
    final actualHighlightStyle =
        highlightStyle ?? style?.copyWith(color: Colors.amber[900]);
    final ranges = getIt.get<SearchEngine>().matchRanges(
      searchWord ?? '',
      text,
      options: options ?? _defaultOptions,
    );
    final spans = _buildSpans(ranges, actualHighlightStyle);
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }

  List<TextSpan> _buildSpans(
    List<MatchRange> ranges,
    TextStyle? actualHighlightStyle,
  ) {
    if (ranges.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, range.start), style: style),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: actualHighlightStyle,
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return spans;
  }
}
