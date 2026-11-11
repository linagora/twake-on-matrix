import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

/// The check of a resolved thread, read as « Resolved ».
class ResolvedMark extends StatelessWidget {
  const ResolvedMark({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4),
    child: Icon(
      Icons.check_circle,
      size: 16,
      semanticLabel: L10n.of(context)!.threadResolved,
      color: LinagoraSysColors.material().primary,
    ),
  );
}
