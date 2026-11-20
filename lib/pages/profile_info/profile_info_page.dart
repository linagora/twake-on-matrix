import 'package:twake_chat/pages/profile_info/profile_info_view.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoPage extends ConsumerStatefulWidget {
  const ProfileInfoPage({
    super.key,
    required this.roomId,
    required this.userId,
    this.onNewChatOpen,
    this.onUpdatedMembers,
    this.onTransferOwnershipSuccess,
  });

  final String roomId;
  final String userId;
  final void Function()? onNewChatOpen;
  final VoidCallback? onUpdatedMembers;
  final VoidCallback? onTransferOwnershipSuccess;

  @override
  ConsumerState<ProfileInfoPage> createState() => ProfileInfoPageState();
}

class ProfileInfoPageState extends ConsumerState<ProfileInfoPage> {
  Room? get room => ref.read(matrixClientProvider).getRoomById(widget.roomId);

  User? get user => room?.unsafeGetUserFromMemoryOrFallback(widget.userId);

  @override
  Widget build(BuildContext context) => ProfileInfoView(
    this,
    onUpdatedMembers: widget.onUpdatedMembers,
    onTransferOwnershipSuccess: widget.onTransferOwnershipSuccess,
  );
}
