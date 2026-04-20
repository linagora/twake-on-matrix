// presentation/controllers/invitation_controller.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '03_invitation_exception.dart';
import '13_invitation_state.dart';
import '15_invitation_providers.dart';

part '14_invitation_controller.g.dart';

@riverpod
class InvitationController extends _$InvitationController {
  @override
  Future<InvitationState> build(String roomId) async {
    // ref.watch creates a subscription: if the service is invalidated,
    // build() is automatically re-executed with the new instance.
    final service = ref.watch(invitationServiceProvider);
    final status = await service.getStatus(roomId);
    if (status.activeLink != null) {
      return InvitationState.linkReady(link: status.activeLink!);
    }
    return const InvitationState.initial();
  }

  Future<void> generateLink() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // ref.read in a method: one-time read, no subscription.
      final link = await ref.read(invitationServiceProvider).generateIfEnabled(roomId);
      return InvitationState.linkReady(link: link);
    });
  }

  Future<void> sendInvitation(String targetUserId) async {
    final current = state.value;
    if (current is! InvitationLinkReady) return;

    state = AsyncValue.data(current.copyWith(isSending: true));
    try {
      await ref.read(invitationServiceProvider).invite(roomId: roomId, targetUserId: targetUserId);
      state = AsyncValue.data(
        InvitationState.sent(targetUserId: targetUserId),
      );
    } on InvitationException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
