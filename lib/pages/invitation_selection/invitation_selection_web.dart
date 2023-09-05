import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:flutter/material.dart';

class InvitationSelectionWebView extends StatelessWidget {
  final String roomId;

  const InvitationSelectionWebView({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: Container(
            width: 448,
            height: 638,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
            ),
            child: InvitationSelection(
              roomId: roomId,
              isFullScreen: false,
            ),
          ),
        ),
      ),
    );
  }
}
