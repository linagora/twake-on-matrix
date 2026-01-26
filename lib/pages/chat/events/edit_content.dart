import 'package:fluffychat/pages/chat/events/edit_content_style.dart';
import 'package:fluffychat/pages/chat/events/reply_content.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class EditContent extends StatelessWidget {
  final Event editEvent;
  final Timeline? timeline;

  const EditContent({
    super.key,
    required this.editEvent,
    this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    final timeline = this.timeline;
    final displayEvent = timeline != null
        ? editEvent.getDisplayEventWithoutEditEvent(timeline)
        : editEvent;
    return Container(
      padding: EditContentStyle.editParentContainerPadding(context),
      decoration: EditContentStyle.editParentContainerDecoration(context),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EditContentStyle.prefixBarVerticalPadding(context),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: EditContentStyle.replyContentSize,
                ),
                width: EditContentStyle.prefixBarWidth,
                decoration: EditContentStyle.prefixBarDecoration(context),
              ),
            ),
            const SizedBox(width: EditContentStyle.contentSpacing),
            if (displayEvent.hasAttachment)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: OptionalSelectionContainerDisabled(
                    isEnabled: PlatformInfos.isWeb,
                    child: ReplyPreviewIconBuilder(
                      event: displayEvent,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    L10n.of(context)!.editMessage,
                    style: EditContentStyle.editTitleDefaultStyle(context),
                  ),
                  if (displayEvent.isCaptionModeOrReply())
                    Text(
                      displayEvent.body,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    )
                  else
                    FutureBuilder<String>(
                      future: displayEvent.calcLocalizedBody(
                        MatrixLocals(L10n.of(context)!),
                        withSenderNamePrefix: false,
                        hideReply: true,
                      ),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ??
                              displayEvent.calcLocalizedBodyFallback(
                                MatrixLocals(L10n.of(context)!),
                                withSenderNamePrefix: false,
                                hideReply: true,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
