import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// Header of the thread screen: "Thread", then the root text on one line.
class ThreadAppBarTitle extends StatelessWidget {
  const ThreadAppBarTitle({super.key, required this.rootText});

  final String rootText;

  @override
  Widget build(BuildContext context) {
    final textStyle = LinagoraTextStyle.material();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(L10n.of(context)!.thread, style: textStyle.titleMedium),
        Text(
          rootText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle.bodySmall.copyWith(
            color: LinagoraSysColors.material().secondary,
          ),
        ),
      ],
    );
  }
}
