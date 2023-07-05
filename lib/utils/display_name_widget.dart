import 'package:flutter/material.dart';

class BuildDisplayName extends StatelessWidget {
  final String? profileDisplayName;
  final String? contactDisplayName;
  final TextStyle? style;
  const BuildDisplayName({
    super.key,
    this.profileDisplayName,
    this.contactDisplayName,
    this.style
  });

  @override
  Widget build(BuildContext context) {
    if (profileDisplayName != null) {
      return _DisplayName(displayName: profileDisplayName!, style: style);
    } else if (contactDisplayName != null) {
      return _DisplayName(displayName: contactDisplayName!, style: style);
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _DisplayName extends StatelessWidget {
  final String displayName;
  final TextStyle? style;
  const _DisplayName({required this.displayName, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      displayName,
      style: style ?? Theme.of(context).textTheme.bodySmall!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}