import 'package:fluffychat/pages/profile_info/profile_info_view.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ProfileInfo extends StatefulWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final String? userId;
  final PresentationContact? contact;
  final bool isInStack;

  const ProfileInfo({
    super.key,
    required this.onBack,
    required this.isInStack,
    this.roomId,
    this.userId,
    this.contact,
  });

  @override
  State<ProfileInfo> createState() => ProfileInfoController();
}

class ProfileInfoController extends State<ProfileInfo> {
  Room? get room => widget.roomId != null
      ? Matrix.of(context).client.getRoomById(widget.roomId!)
      : null;

  User? get user => room?.unsafeGetUserFromMemoryOrFallback(
        room?.directChatMatrixID ?? widget.userId ?? '',
      );

  @override
  Widget build(BuildContext context) {
    return ProfileInfoView(this);
  }
}
