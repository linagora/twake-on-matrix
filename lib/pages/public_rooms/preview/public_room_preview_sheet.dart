import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
import 'package:twake_chat/domain/model/public_rooms/room_address.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/preview/public_room_preview_controller.dart';
import 'package:twake_chat/pages/public_rooms/preview/public_room_preview_state.dart';
import 'package:twake_chat/pages/public_rooms/public_room_kind_badge.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The preview of a room the user is not in, opened from its address.
class PublicRoomPreviewSheet extends ConsumerStatefulWidget {
  const PublicRoomPreviewSheet({
    super.key,
    required this.address,
    this.eventId,
    this.webLink,
  });

  final RoomAddress address;
  final String? eventId;

  /// The web link the user tapped, offered when the room cannot be
  /// previewed: it may be a page of another site.
  final String? webLink;

  @override
  ConsumerState<PublicRoomPreviewSheet> createState() =>
      _PublicRoomPreviewSheetState();
}

class _PublicRoomPreviewSheetState
    extends ConsumerState<PublicRoomPreviewSheet> {
  void _openRoom(String roomId) {
    context.pop();
    RoomRoute(roomid: roomId, event: widget.eventId).go(context);
  }

  /// Closes the sheet only once the browser opened, else says so.
  Future<void> _openInBrowser(String link) async {
    final launched = await launchUrlString(
      link,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!mounted) return;
    if (launched) {
      // Dismissed while the browser opened: pop nothing else.
      if (ModalRoute.of(context)?.isCurrent ?? false) context.pop();
    } else {
      TwakeSnackBar.show(context, L10n.of(context)!.cantOpenUri(link));
    }
  }

  Future<void> _open() async {
    final l10n = L10n.of(context)!;
    final result = await ref
        .read(publicRoomPreviewControllerProvider(widget.address).notifier)
        .open();
    if (!mounted) return;
    switch (result) {
      case PublicRoomJoined(:final roomId):
        _openRoom(roomId);
      case PublicRoomJoinedNotInSync():
        TwakeSnackBar.show(context, l10n.youJoinedTheChat);
        context.pop();
      case PublicRoomRequested() ||
          PublicRoomOpenFailed() ||
          PublicRoomOpenIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = publicRoomPreviewControllerProvider(widget.address);
    ref.listen(provider, (_, next) {
      if (next.value?.preview case PublicRoomPreviewJoined(:final roomId)) {
        _openRoom(roomId);
      }
    });
    final state = ref.watch(provider);
    final preview = state.hasError
        ? const PublicRoomPreview.unavailable()
        : state.value?.preview;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: switch (preview) {
            null || PublicRoomPreviewJoined() => const Center(
              heightFactor: 3,
              child: CircularProgressIndicator.adaptive(),
            ),
            final preview => _PublicRoomPreviewBody(
              preview: preview,
              state: state.value,
              onOpen: _open,
              onOpenInBrowser: switch (widget.webLink) {
                final link? => () => _openInBrowser(link),
                null => null,
              },
            ),
          },
        ),
      ),
    );
  }
}

class _PublicRoomPreviewBody extends StatelessWidget {
  const _PublicRoomPreviewBody({
    required this.preview,
    required this.state,
    required this.onOpen,
    this.onOpenInBrowser,
  });

  final PublicRoomPreview preview;
  final PublicRoomPreviewState? state;
  final VoidCallback onOpen;
  final VoidCallback? onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final theme = Theme.of(context);
    final onPressed = state?.isPending ?? false ? null : onOpen;
    final isApproval = switch (preview) {
      PublicRoomPreviewFound(:final room) =>
        room.access == PublicRoomAccess.approval,
      _ => false,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        ...switch (preview) {
          PublicRoomPreviewFound(:final room, :final isRequested) => [
            _PublicRoomSummary(room: room),
            if (isRequested)
              Text(
                l10n.publicGroupRequestSentMembers(room.memberCount),
                style: theme.textTheme.bodyMedium,
              )
            else
              FilledButton(
                onPressed: onPressed,
                child: Text(
                  isApproval
                      ? l10n.askToJoinPublicGroupMembers(room.memberCount)
                      : l10n.joinPublicGroupMembers(room.memberCount),
                ),
              ),
          ],
          PublicRoomPreviewBanned() => [
            Text(
              l10n.youHaveBeenBannedFromThisChat,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
          _ => [
            Text(
              l10n.publicGroupUnavailable,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            FilledButton(onPressed: onPressed, child: Text(l10n.tryToJoin)),
            if (onOpenInBrowser case final open?)
              OutlinedButton(onPressed: open, child: Text(l10n.openInBrowser)),
          ],
        },
        if (state?.hasFailed ?? false)
          Text(
            isApproval
                ? l10n.publicGroupRequestFailed
                : l10n.publicGroupJoinFailed,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _PublicRoomSummary extends StatelessWidget {
  const _PublicRoomSummary({required this.room});

  final PublicRoom room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = room.topic;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        AvatarWithKindBadge(
          mxContent: room.avatarUri,
          name: room.name,
          badge: room.kindBadge,
          size: AvatarStyle.defaultSize * 2,
        ),
        Text(
          room.name,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (topic != null && topic.isNotEmpty)
          Text(
            topic,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
