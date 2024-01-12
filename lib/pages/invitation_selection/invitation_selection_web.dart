import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_style.dart';
import 'package:flutter/material.dart';

class InvitationSelectionWebView extends StatelessWidget {
  final String roomId;

  const InvitationSelectionWebView({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: InvitationSelectionStyle.dialogWidth,
        height: InvitationSelectionStyle.dialogHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(InvitationSelectionStyle.dialogBorderRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InvitationSelection(
          roomId: roomId,
          isFullScreen: false,
        ),
      ),
    );
  }
}
