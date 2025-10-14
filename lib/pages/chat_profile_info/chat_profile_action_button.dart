import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatProfileActionButton extends StatelessWidget {
  const ChatProfileActionButton({
    super.key,
    required this.title,
    required this.iconData,
    required this.onTap,
  });

  final String title;
  final IconData iconData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 15),
        decoration: BoxDecoration(
          color: LinagoraSysColors.material().onPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              iconData,
              color: LinagoraRefColors.material().primary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11,
                height: 16 / 11,
                color: LinagoraSysColors.material().primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
