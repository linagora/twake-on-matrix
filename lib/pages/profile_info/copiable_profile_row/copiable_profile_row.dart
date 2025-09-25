import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/copiable_profile_row_style.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class CopiableProfileRow extends StatelessWidget {
  static const snackBarDuration = Duration(milliseconds: 500);

  final String caption;
  final String copiableText;
  final Widget leadingIcon;
  final bool enableDividerTop;

  const CopiableProfileRow({
    required this.leadingIcon,
    required this.caption,
    required this.copiableText,
    this.enableDividerTop = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: CopiableProfileRowStyle.copiableRowPadding,
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
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
                  border: enableDividerTop
                      ? Border(
                          top: BorderSide(
                            color: LinagoraSysColors.material()
                                .surfaceTint
                                .withOpacity(
                                  CopiableProfileRowStyle.borderOpacity,
                                ),
                          ),
                        )
                      : null,
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
                        InkWell(
                          borderRadius: BorderRadius.circular(38),
                          splashColor: LinagoraHoverStyle.material().hoverColor,
                          onTap: () {
                            TwakeClipboard.instance.copyText(copiableText);
                            TwakeSnackBar.show(
                              duration: snackBarDuration,
                              context,
                              L10n.of(context)!.copiedToClipboard,
                            );
                          },
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.content_copy,
                              size: ChatProfileInfoStyle.copyIconSize,
                            ),
                          ),
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
