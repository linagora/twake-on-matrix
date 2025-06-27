import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/copiable_profile_row_style.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class CopiableProfileRow extends StatelessWidget {
  static const snackBarDuration = Duration(milliseconds: 500);

  final String caption;
  final String copiableText;
  final Widget leadingIcon;

  const CopiableProfileRow({
    required this.leadingIcon,
    required this.caption,
    required this.copiableText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: CopiableProfileRowStyle.copiableRowPadding,
      child: TwakeInkWell(
        onTap: () {
          TwakeClipboard.instance.copyText(copiableText);
          TwakeSnackBar.show(
            duration: snackBarDuration,
            context,
            L10n.of(context)!.copiedToClipboard,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                leadingIcon,
              ],
            ),
            const SizedBox(
              width: CopiableProfileRowStyle.spacerBetweenLeadingIconAndContent,
            ),
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: LinagoraSysColors.material()
                          .surfaceTint
                          .withOpacity(CopiableProfileRowStyle.borderOpacity),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: LinagoraRefColors.material().neutral[40],
                          ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            copiableText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: LinagoraSysColors.material().onSurface,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.content_copy,
                          size: ChatProfileInfoStyle.copyIconSize,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: CopiableProfileRowStyle.textColumnBottomPadding,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
