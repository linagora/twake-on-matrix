import 'package:flutter/material.dart';

class BuildDisplayName extends StatelessWidget {
  final String? profileDisplayName;
  final String? contactDisplayName;
  final String highlightKeyword;
  final TextStyle? style;
  const BuildDisplayName({
    super.key,
    this.profileDisplayName,
    this.contactDisplayName,
    this.highlightKeyword = "",
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profileDisplayName ?? contactDisplayName;
    if (displayName == null) {
      return const SizedBox.shrink();
    }
    return Text(
      displayName,
      style:
          style ??
          Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
