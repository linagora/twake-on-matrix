import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/copiable_profile_row_style.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
      padding: ProfileInfoBodyViewStyle.copiableRowPadding,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: CopiableProfileRowStyle.rippleRadius,
        ),
        onTap: () {
          TwakeClipboard.instance.copyText(copiableText);
          TwakeSnackBar.show(
            duration: snackBarDuration,
            context,
            L10n.of(context)!.copiedToClipboard,
          );
        },
        child: Padding(
          padding: CopiableProfileRowStyle.ripplePadding,
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
                width:
                    CopiableProfileRowStyle.spacerBetweenLeadingIconAndContent,
              ),
              Expanded(
                child: DecoratedBox(
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              copiableText,
                              style: Theme.of(context).textTheme.titleMedium,
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
      ),
    );
  }
}
