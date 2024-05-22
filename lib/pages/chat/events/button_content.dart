import 'package:fluffychat/pages/chat/events/button_content_style.dart';
import 'package:flutter/material.dart';

class ButtonContent extends StatelessWidget {
  final Function onTap;
  final IconData icon;
  final String title;

  const ButtonContent({
    super.key,
    required this.onTap,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ButtonContentStyle.parentPadding,
      child: InkWell(
        onTap: () => onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onError,
                    shape: BoxShape.circle,
                  ),
                  padding: ButtonContentStyle.leadingIconPadding,
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: ButtonContentStyle.leadingIconSize,
                  ),
                ),
                const SizedBox(width: ButtonContentStyle.leadingAndTextGap),
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: ButtonContentStyle.textMaxWidth,
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
