import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/new_group/usecases/create_group_usecase.provider.dart';
import 'package:twake_chat/domain/new_group/usecases/invite_users_usecase.provider.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'new_group_chat_info_controller.g.dart';

@riverpod
class NewGroupChatInfoController extends _$NewGroupChatInfoController {
  @override
  NewGroupChatInfoState build() => const NewGroupChatInfoState.idle();

  Future<void> create(
    CreateNewGroupChatRequest request, {
    required bool isFeed,
  }) async {
    if (state.isBusy) return;
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
