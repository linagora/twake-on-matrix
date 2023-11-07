import 'package:fluffychat/pages/chat_direct_details/chat_direct_details_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatDirectDetails extends StatefulWidget {
  final VoidCallback? onBack;
  final String? roomId;

  const ChatDirectDetails({
    super.key,
    required this.onBack,
    this.roomId,
  });

  @override
  State<ChatDirectDetails> createState() => ChatDirectDetailsController();
}

class ChatDirectDetailsController extends State<ChatDirectDetails> {
  Room? get room => widget.roomId != null
      ? Matrix.of(context).client.getRoomById(widget.roomId!)
      : null;

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  @override
  Widget build(BuildContext context) {
    return ChatDirectDetailsView(this);
  }
}
