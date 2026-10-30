import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/new_group/usecases/create_group_usecase.provider.dart';
import 'package:twake_chat/domain/new_group/usecases/invite_users_usecase.provider.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_state.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/pages/new_group/states/new_group_form.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

part 'new_group_chat_info_controller.g.dart';

@riverpod
class NewGroupChatInfoController extends _$NewGroupChatInfoController {
  @override
  NewGroupChatInfoState build() => const NewGroupChatInfoState.idle();

  /// Ignored while busy; a partial invite failure still ends in `done`.
  Future<void> create(NewGroupForm form) async {
    if (state.isBusy) return;
    final request = _toRequest(form);
    state = const NewGroupChatInfoState.creating();
    final roomId = await _createRoom(request, isFeed: form.isFeed);
    if (!ref.mounted || roomId == null) return;
    final inviteFailure = await _invite(roomId, request.invite);
    if (!ref.mounted) return;
    state = NewGroupChatInfoState.done(
      roomId: roomId,
      groupName: request.groupName,
      inviteFailure: inviteFailure,
    );
  }

  CreateNewGroupChatRequest _toRequest(NewGroupForm form) {
    final userId = ref.read(activeMatrixClientProvider).userId;
    return CreateNewGroupChatRequest(
      groupName: form.groupName,
      invite: form.invitees.nonNulls.where((id) => id != userId).toList(),
      enableEncryption: form.enableEncryption,
      isPublic:
          form.privacy.isPublic &&
          ref.read(loginHomeserverSummaryProvider).isPublicGroupsEnabled,
      isServerLimited: form.privacy.isServerLimited,
      urlAvatar: form.urlAvatar,
    );
  }

  Future<String?> _createRoom(
    CreateNewGroupChatRequest request, {
    required bool isFeed,
  }) async {
    try {
      return isFeed
          ? await _createFeed(request)
          : await ref.read(createGroupUseCaseProvider).execute(request);
    } on FeedNotSupportedByHomeserverException {
      _fail(NewGroupFailureReason.feedNotSupported);
    } on Object {
      _fail(NewGroupFailureReason.other);
    }
    return null;
  }

  void _fail(NewGroupFailureReason reason) {
    if (!ref.mounted) return;
    state = NewGroupChatInfoState.failed(reason);
  }

  Future<InviteUserPartialFailureException?> _invite(
    String roomId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return null;
    state = const NewGroupChatInfoState.inviting();
    try {
      await ref
          .read(inviteUsersUseCaseProvider)
          .execute(roomId: roomId, userIds: userIds);
      return null;
    } on InviteUserPartialFailureException catch (exception) {
      return exception;
    }
  }

  Future<String> _createFeed(CreateNewGroupChatRequest request) {
    final client = ref.read(activeMatrixClientProvider).client;
    if (client == null) throw StateError('No active Matrix client');
    return ref
        .read(createNewFeedInteractorProvider(client))
        .execute(feedName: request.groupName, avatarUrl: request.urlAvatar);
  }
}
