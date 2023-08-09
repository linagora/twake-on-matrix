import 'package:flutter/material.dart';

class TwakeChip extends StatelessWidget {
  final String text;

  final EdgeInsets paddingText;

  final Color textColor;

  const TwakeChip({
    super.key,
    required this.text,
    this.paddingText =
        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.08),
      ),
      child: Padding(
        padding: paddingText,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
              ),
        ),
      ),
    );
  }
}
