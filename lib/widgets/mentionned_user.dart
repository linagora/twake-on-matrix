import 'package:fluffychat/utils/string_extension.dart';
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

  final int _maxCharactersDisplayNameForPill = 12;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call(url);
      },
      child: Text(
        displayName.shortenDisplayName(
          maxCharacters: _maxCharactersDisplayNameForPill,
        ),
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
