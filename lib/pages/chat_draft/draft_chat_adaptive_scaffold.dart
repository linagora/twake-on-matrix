import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_navigator.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_builder.dart';

class DraftChatAdaptiveScaffold extends StatelessWidget {
  final GoRouterState state;

  const DraftChatAdaptiveScaffold({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ChatAdaptiveScaffoldBuilder(
      bodyBuilder: (controller) => DraftChat(
        contact: _contact,
        onChangeRightColumnType: controller.setRightColumnType,
      ),
      rightBuilder: (
        controller, {
        required bool isInStack,
        required RightColumnType type,
      }) {
        switch (type) {
          case RightColumnType.profileInfo:
            return ChatProfileInfoNavigator(
              onBack: controller.hideRightColumn,
              contact: _contact,
              isInStack: isInStack,
              isDraftInfo: true,
            );
          default:
            return const SizedBox();
        }
      },
    );
  }

  PresentationContact get _contact {
    final extra = state.extra as Map<String, String>;
    if (extra.isNotEmpty) {
      return PresentationContact(
        matrixId: extra[PresentationContactConstant.receiverId],
        email: extra[PresentationContactConstant.email],
        displayName: extra[PresentationContactConstant.displayName],
      );
    } else {
      return const PresentationContact().presentationContactEmpty;
    }
  }
}
