import 'package:fluffychat/pages/chat_list/chat_list_skeletonizer_style.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatListSkeletonizerWidget extends StatelessWidget {
  const ChatListSkeletonizerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      ignoreContainers: true,
      child: ListView.builder(
        itemCount: ChatListSkeletonizerStyle.itemCount,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.ac_unit,
                size: ChatListSkeletonizerStyle.iconSize,
              ),
              title: Text(
                ChatListSkeletonizerStyle.titleHardCode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ChatListSkeletonizerStyle.subtitleHardCode,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    ChatListSkeletonizerStyle.subtitleHardCode,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
