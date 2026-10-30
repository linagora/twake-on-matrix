import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/new_group/usecases/create_group_usecase.provider.dart';
import 'package:twake_chat/domain/new_group/usecases/invite_users_usecase.provider.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'new_group_chat_info_controller.g.dart';

@riverpod
class NewGroupChatInfoController extends _$NewGroupChatInfoController {
  @override
  NewGroupChatInfoState build() => const NewGroupChatInfoState.idle();

  /// Ignored while busy; a partial invite failure still ends in `done`.
  Future<void> create({
    required String groupName,
    required Iterable<String?> invitees,
    required bool enableEncryption,
    required GroupPrivacyState privacy,
    required bool isFeed,
    String? urlAvatar,
  }) async {
    if (state.isBusy) return;
    final userId = ref.read(activeMatrixClientProvider).userId;
    final request = CreateNewGroupChatRequest(
      groupName: groupName,
      invite: invitees.nonNulls.where((id) => id != userId).toList(),
      enableEncryption: enableEncryption,
      isPublic:
          privacy.isPublic &&
          ref.read(loginHomeserverSummaryProvider).isPublicGroupsEnabled,
      isServerLimited: privacy.isServerLimited,
      urlAvatar: urlAvatar,
    );
    state = const NewGroupChatInfoState.creating();
    final String roomId;
    try {
      roomId = isFeed
          ? await _createFeed(request)
          : await ref.read(createGroupUseCaseProvider).execute(request);
    } on FeedNotSupportedByHomeserverException {
      if (!ref.mounted) return;
      state = const NewGroupChatInfoState.failed(
        NewGroupFailureReason.feedNotSupported,
      );
      return;
    } on Object {
      if (!ref.mounted) return;
      state = const NewGroupChatInfoState.failed(NewGroupFailureReason.other);
      return;
    }
    if (!ref.mounted) return;
    if (request.invite.isEmpty) {
      state = NewGroupChatInfoState.done(
        roomId: roomId,
        groupName: request.groupName,
      );
      return;
    }
    state = const NewGroupChatInfoState.inviting();
    InviteUserPartialFailureException? inviteFailure;
    try {
      await ref
          .read(inviteUsersUseCaseProvider)
          .execute(roomId: roomId, userIds: request.invite);
    } on InviteUserPartialFailureException catch (exception) {
      inviteFailure = exception;
    }
    if (!ref.mounted) return;
    state = NewGroupChatInfoState.done(
      roomId: roomId,
      groupName: request.groupName,
      inviteFailure: inviteFailure,
    );
  }

  Future<String> _createFeed(CreateNewGroupChatRequest request) {
    final client = ref.read(activeMatrixClientProvider).client;
    if (client == null) throw StateError('No active Matrix client');
    return ref
        .read(createNewFeedInteractorProvider(client))
        .execute(feedName: request.groupName, avatarUrl: request.urlAvatar);
  }
}
