import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class TextMessageRetryButton extends StatelessWidget {
  const TextMessageRetryButton({
    super.key,
    required this.event,
    this.onRetry,
  });

  final Event event;
  final Future<void> Function(Event)? onRetry;

  @override
  Widget build(BuildContext context) {
    if (event.status != EventStatus.error) return const SizedBox();
    if (event.messageType != MessageTypes.Text) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 16,
      child: TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: onRetry != null ? () => onRetry!(event) : null,
        child: Text(
          L10n.of(context)!.tapToRetry,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                height: 16 / 12,
                color: LinagoraSysColors.material().primary,
              ),
        ),
      ),
    );
  }
}
