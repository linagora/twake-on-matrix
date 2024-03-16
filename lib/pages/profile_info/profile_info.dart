import 'package:fluffychat/pages/profile_info/profile_info_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ProfileInfo extends StatefulWidget {
  const ProfileInfo({
    super.key,
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  State<ProfileInfo> createState() => ProfileInfoState();
}

class ProfileInfoState extends State<ProfileInfo> {
  Room? get room => Matrix.of(context).client.getRoomById(widget.roomId);

  User? get user => room?.unsafeGetUserFromMemoryOrFallback(widget.userId);

  @override
  Widget build(BuildContext context) => ProfileInfoView(this);
}
