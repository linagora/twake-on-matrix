import 'package:fluffychat/pages/chat_direct_details/chat_direct_details.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
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
        state: state,
        onChangeRightColumnType: controller.setRightColumnType,
      ),
      rightBuilder: (
        controller, {
        required bool isInStack,
        required RightColumnType type,
      }) {
        return Navigator(
          initialRoute: type.initialRoute,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case RightColumnRouteNames.chatDirectDetails:
                return MaterialPageRoute(
                  builder: (_) => ChatDirectDetails(
                    onBack: controller.hideRightColumn,
                  ),
                );
            }
            return MaterialPageRoute(builder: (_) => const SizedBox());
          },
        );
      },
    );
  }
}
