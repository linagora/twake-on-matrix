import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_background.dart';
import 'package:fluffychat/pages/chat/chat_invitation_body_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatInvitationBody extends StatelessWidget with MessageContentMixin {
  final ChatController controller;

  const ChatInvitationBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const ChatBackground(),
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
                  Expanded(child: _buildInvitationContent(context)),
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
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ChatInvitationBodyStyle.maxWidth(context),
        ),
        decoration: BoxDecoration(
          color: ChatInvitationBodyStyle.backgroundColor,
          borderRadius: BorderRadius.circular(
            ChatInvitationBodyStyle.dialogBorderRadius,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ChatInvitationBodyStyle.dialogPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                ImagePaths.mascotInvite,
                width: ChatInvitationBodyStyle.iconSize(context),
                height: ChatInvitationBodyStyle.iconSize(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  controller.displayInviterName,
                  style: ChatInvitationBodyStyle.subTitleStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                L10n.of(context)!.hasInvitedYouToAChat,
                style: ChatInvitationBodyStyle.titleStyle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InvitationRejectButton(
                      onReject: () => controller.onRejectInvitation(context),
                    ),
                  ),
                  const SizedBox(
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
    );
  }
}

class InvitationAcceptButton extends StatelessWidget {
  final Function() onAccept;

  const InvitationAcceptButton({required this.onAccept, super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        foregroundColor: WidgetStateProperty.all<Color>(
          Theme.of(context).colorScheme.onPrimary,
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ChatInvitationBodyStyle.dialogButtonBorderRadius,
            ),
          ),
        ),
        side: WidgetStateProperty.all<BorderSide>(BorderSide.none),
        fixedSize: WidgetStateProperty.all<Size>(
          const Size.fromHeight(ChatInvitationBodyStyle.dialogButtonHeight),
        ),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      onPressed: onAccept,
      child: Text(L10n.of(context)!.accept),
    );
  }
}

class InvitationRejectButton extends StatelessWidget {
  final Function() onReject;

  const InvitationRejectButton({required this.onReject, super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
          Theme.of(context).colorScheme.surface,
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ChatInvitationBodyStyle.dialogButtonBorderRadius,
            ),
          ),
        ),
        side: WidgetStateProperty.all<BorderSide>(
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0),
        ),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 24),
        ),
        fixedSize: WidgetStateProperty.all<Size>(
          const Size.fromHeight(ChatInvitationBodyStyle.dialogButtonHeight),
        ),
      ),
      onPressed: onReject,
      child: Text(L10n.of(context)!.reject),
    );
  }
}

class InvitationBottomBar extends StatelessWidget {
  const InvitationBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        ChatInvitationBodyStyle.chatInvitationBottomBarPadding,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            const SizedBox(
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
