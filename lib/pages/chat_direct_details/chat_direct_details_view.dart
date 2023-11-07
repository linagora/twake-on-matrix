import 'package:fluffychat/pages/chat_direct_details/chat_direct_details.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatDirectDetailsView extends StatelessWidget {
  final ChatDirectDetailsController controller;
  const ChatDirectDetailsView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              onPressed: controller.widget.onBack,
              icon: const Icon(Icons.close),
            ),
            Text(
              L10n.of(context)!.contactInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Avatar(
            mxContent: controller.user?.avatarUrl,
            name: controller.user?.calcDisplayname(),
            size: AvatarStyle.defaultSize * 2,
            fontSize: 24,
          ),
        ],
      ),
    );
  }
}
