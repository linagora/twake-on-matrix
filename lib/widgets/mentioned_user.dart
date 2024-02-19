import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/text_parser.dart';

class MentionedUser extends StatelessWidget {
  final String displayName;
  final String url;
  final OnPillTap? onTap;
  final TextStyle? textStyle;
  final int? maxLines;

  const MentionedUser({
    Key? key,
    required this.displayName,
    required this.url,
    this.textStyle,
    this.onTap,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap?.call(url);
      },
      mouseCursor: SystemMouseCursors.click,
      child: Text(
        displayName,
        style: textStyle,
        maxLines: maxLines,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
