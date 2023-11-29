import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/profile_info/profile_info_navigator.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/presentation/model/draft_chat_constant.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_constant.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_builder.dart';

class DraftChatAdaptiveScaffold extends StatelessWidget {
  final GoRouterState state;

  const DraftChatAdaptiveScaffold({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChatAdaptiveScaffoldBuilder(
      bodyBuilder: (controller) => DraftChat(
        contact: _contact,
        enableEncryption: _enableEncryption,
        onChangeRightColumnType: controller.setRightColumnType,
      ),
      rightBuilder: (
        controller, {
        required bool isInStack,
        required RightColumnType type,
      }) {
        switch (type) {
          case RightColumnType.profileInfo:
            return ProfileInfoNavigator(
              onBack: controller.hideRightColumn,
              contact: _contact,
              isInStack: isInStack,
            );
          default:
            return const SizedBox();
        }
      },
    );
  }

  bool get _enableEncryption {
    return (state.extra
        as Map<String, dynamic>)[DraftChatConstant.enableEncryption];
  }

  PresentationContact get _contact {
    final contact = (state.extra
        as Map<String, dynamic>)[PresentationContactConstant.contact];
    if (contact.isNotEmpty) {
      return PresentationContact(
        matrixId: contact[PresentationContactConstant.receiverId],
        email: contact[PresentationContactConstant.email],
        displayName: contact[PresentationContactConstant.displayName],
      );
    } else {
      return const PresentationContact().presentationContactEmpty;
    }
  }
}
