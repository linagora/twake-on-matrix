import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_invitation_body_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatInvitationBody extends StatelessWidget with MessageContentMixin {
  final ChatController controller;

  const ChatInvitationBody(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (Matrix.of(context).wallpaper != null)
          Image.file(
            Matrix.of(context).wallpaper!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        SafeArea(
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  Expanded(
                    child: _buildInvitationContent(context),
                  ),
                  const InvitationBottomBar(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationContent(BuildContext context) {
    return Center(
      child: UnconstrainedBox(
        child: Container(
          width: ChatInvitationBodyStyle.dialogWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(
              ChatInvitationBodyStyle.dialogBorderRadius,
            ),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.surfaceTint.withOpacity(0.16),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(ChatInvitationBodyStyle.dialogPadding),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(
                    ChatInvitationBodyStyle.dialogTextPadding,
                  ),
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${controller.displayInviterName} \n',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        TextSpan(
                          text: L10n.of(context)!.hasInvitedYouToAChat,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InvitationRejectButton(
                        onReject: () => controller.onRejectInvitation(context),
                      ),
                    ),
                    SizedBox(
                      width: ChatInvitationBodyStyle.dialogButtonSpacing,
                    ),
                    Expanded(
                      child: InvitationAcceptButton(
                        onAccept: () => controller.onAcceptInvitation(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InvitationAcceptButton extends StatelessWidget {
  final Function() onAccept;

  const InvitationAcceptButton({
    required this.onAccept,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        foregroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.onPrimary,
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ChatInvitationBodyStyle.dialogButtonBorderRadius,
            ),
          ),
        ),
        side: MaterialStateProperty.all<BorderSide>(BorderSide.none),
        fixedSize: MaterialStateProperty.all<Size>(
          Size.fromHeight(ChatInvitationBodyStyle.dialogButtonHeight),
        ),
      ),
      onPressed: onAccept,
      child: Text(L10n.of(context)!.accept),
    );
  }
}

class InvitationRejectButton extends StatelessWidget {
  final Function() onReject;

  const InvitationRejectButton({
    required this.onReject,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.surface,
        ),
        foregroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.error,
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ChatInvitationBodyStyle.dialogButtonBorderRadius,
            ),
          ),
        ),
        side: MaterialStateProperty.all<BorderSide>(BorderSide.none),
        fixedSize: MaterialStateProperty.all<Size>(
          Size.fromHeight(ChatInvitationBodyStyle.dialogButtonHeight),
        ),
      ),
      onPressed: onReject,
      child: Text(L10n.of(context)!.reject),
    );
  }
}

class InvitationBottomBar extends StatelessWidget {
  const InvitationBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ChatInvitationBodyStyle.chatInvitationBottomBarPadding,
      ),
      color: Theme.of(context).colorScheme.surfaceVariant,
      height: ChatInvitationBodyStyle.chatInvitationBottomBarHeight,
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: ChatInvitationBodyStyle.chatInvitationBottomBarIconSize,
              color: LinagoraRefColors.material().tertiary[30],
            ),
            SizedBox(
              width: ChatInvitationBodyStyle.chatInvitationBottomBarIconSpacing,
            ),
            Flexible(
              child: Text(
                L10n.of(context)!.youNeedToAcceptTheInvitation,
                maxLines: 2,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
