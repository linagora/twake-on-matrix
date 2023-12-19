import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/text_parser.dart';

class MentionnedUser extends StatelessWidget {
  final String displayName;
  final String url;
  final OnPillTap? onTap;
  final TextStyle? textStyle;

  const MentionnedUser({
    Key? key,
    required this.displayName,
    required this.url,
    this.textStyle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call(url);
      },
      child: Text(
        displayName,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
