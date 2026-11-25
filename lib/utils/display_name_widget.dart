import 'package:twake_chat/widgets/highlight_text.dart';
import 'package:flutter/material.dart';

class BuildDisplayName extends StatelessWidget {
  final String? profileDisplayName;
  final String? contactDisplayName;
  final String highlightKeyword;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  const BuildDisplayName({
    super.key,
    this.profileDisplayName,
    this.contactDisplayName,
    this.highlightKeyword = "",
    this.style,
    this.maxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profileDisplayName ?? contactDisplayName;
    if (displayName == null) {
      return const SizedBox.shrink();
    }
    return HighlightText(
      text: displayName,
      searchWord: highlightKeyword,
      style:
          style ??
          Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
