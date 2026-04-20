// presentation/pages/invitation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '01_invitation_link.dart';
import '03_invitation_exception.dart';
import '13_invitation_state.dart';
import '14_invitation_controller.dart';

class InvitationPage extends ConsumerWidget {
  const InvitationPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch → rebuild when state changes
    final state = ref.watch(invitationControllerProvider(roomId));

    // ref.listen in build() → side effect without rebuild (snackbar, navigation)
    ref.listen(invitationControllerProvider(roomId), (_, next) {
      next.whenOrNull(
        error: (e, _) => switch (e) {
          InvitationDisabledException() =>
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invitations disabled')),
            ),
          InvitationNetworkException() =>
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Network error, please retry')),
            ),
          _ => null,
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Invite')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const SizedBox.shrink(), // handled by ref.listen
        data: (invitationState) => switch (invitationState) {
          InvitationInitial() => _IdleView(
              onGenerate: () => ref
                  .read(invitationControllerProvider(roomId).notifier)
                  .generateLink(),
            ),
          InvitationLinkReady(:final link, :final isSending) => _LinkView(
              link: link,
              isSending: isSending,
              onSend: (userId) => ref
                  .read(invitationControllerProvider(roomId).notifier)
                  .sendInvitation(userId),
            ),
          InvitationSent(:final targetUserId) => _SuccessView(
              userId: targetUserId,
              onDone: () => Navigator.of(context).pop(),
            ),
        },
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => Center(
        child: ElevatedButton(
          onPressed: onGenerate,
          child: const Text('Generate a link'),
        ),
      );
}

class _LinkView extends StatelessWidget {
  const _LinkView({
    required this.link,
    required this.isSending,
    required this.onSend,
  });
  final InvitationLink link;
  final bool isSending;
  final void Function(String userId) onSend;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(link.url),
          if (isSending)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: () => onSend('@user:server'),
              child: const Text('Send'),
            ),
        ],
      );
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.userId, required this.onDone});
  final String userId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('Invitation sent to $userId'),
          ElevatedButton(onPressed: onDone, child: const Text('Close')),
        ],
      );
}
