import 'package:fluffychat/pages/profile_info/profile_info_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({
    super.key,
    required this.roomId,
    required this.userId,
    this.onNewChatOpen,
    this.onUpdatedMembers,
  });

  final String roomId;
  final String userId;
  final void Function()? onNewChatOpen;
  final VoidCallback? onUpdatedMembers;

  @override
  State<ProfileInfoPage> createState() => ProfileInfoPageState();
}

class ProfileInfoPageState extends State<ProfileInfoPage> {
  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  User? get user => room?.unsafeGetUserFromMemoryOrFallback(widget.userId);

  @override
  Widget build(BuildContext context) => ProfileInfoView(
        this,
        onUpdatedMembers: widget.onUpdatedMembers,
      );
}
