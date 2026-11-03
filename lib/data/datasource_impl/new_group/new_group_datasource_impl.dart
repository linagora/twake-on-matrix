import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/new_group/new_group_datasource.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/utils/power_level_manager.dart';

class NewGroupDatasourceImpl implements NewGroupDatasource {
  const NewGroupDatasourceImpl(this._client);

  static const int _maxInviteRetries = 3;

  final Client? _client;

  Client get _activeClient =>
      _client ?? (throw StateError('No active Matrix client'));

  @override
  Future<String> createGroup(CreateNewGroupChatRequest request) async {
    try {
      return await _createGroupChat(request);
    } catch (exception, stackTrace) {
      Logs().e('NewGroupDatasourceImpl::createGroup', exception, stackTrace);
      rethrow;
    }
  }

  Future<String> _createGroupChat(CreateNewGroupChatRequest request) {
    final isPublic = request.isPublic;
    final enableEncryption = isPublic ? false : request.enableEncryption;
    final historyVisibility = enableEncryption == true
        ? HistoryVisibility.joined
        : HistoryVisibility.shared;
    final powerLevelManager = PowerLevelManager();
    return _activeClient.createGroupChat(
      groupName: request.groupName,
      enableEncryption: enableEncryption,
      preset: isPublic
          ? CreateRoomPreset.publicChat
          : CreateRoomPreset.privateChat,
      visibility: isPublic ? Visibility.public : null,
      initialState: [
        StateEvent(
          type: EventTypes.RoomAvatar,
          content: {'url': request.urlAvatar},
          stateKey: '',
        ),
        StateEvent(
          type: EventTypes.HistoryVisibility,
          content: {'history_visibility': historyVisibility.name},
          stateKey: '',
        ),
      ],
      powerLevelContentOverride: {
        'events': powerLevelManager.getDefaultPowerLevelEventForMember(),
        'invite': powerLevelManager.getAdminPowerLevel(),
        'kick': powerLevelManager.getAdminPowerLevel(),
      },
    );
  }

  @override
  Future<void> inviteUser({
    required String roomId,
    required String userId,
  }) async {
    final client = _activeClient;
    for (var attempt = 1; ; attempt++) {
      final retryAfter = await _tryInvite(client, roomId, userId, attempt);
      if (retryAfter == null) return;
      if (retryAfter > Duration.zero) await Future.delayed(retryAfter);
    }
  }

  /// Returns null once invited, or the delay before the next attempt.
  Future<Duration?> _tryInvite(
    Client client,
    String roomId,
    String userId,
    int attempt,
  ) async {
    try {
      await client.inviteUser(roomId, userId);
      return null;
    } on MatrixException catch (exception, stackTrace) {
      Logs().e(
        'NewGroupDatasourceImpl::inviteUser: attempt $attempt/$_maxInviteRetries',
        exception,
        stackTrace,
      );
      if (exception.errcode != 'M_LIMIT_EXCEEDED' ||
          attempt >= _maxInviteRetries) {
        throw _toInviteUserException(userId, exception);
      }
      return Duration(milliseconds: exception.retryAfterMs ?? 0);
    } on Exception catch (exception, stackTrace) {
      Logs().e('NewGroupDatasourceImpl::inviteUser', exception, stackTrace);
      throw GenericInviteException(
        userId: userId,
        message: exception.toString(),
      );
    }
  }

  InviteUserException _toInviteUserException(
    String userId,
    MatrixException exception,
  ) {
    final message = exception.errorMessage;
    if (exception.errcode == 'M_BAD_STATE' &&
        message.contains('Cannot invite user who was banned')) {
      return UserBannedException(userId: userId, message: message);
    }
    return GenericInviteException(userId: userId, message: message);
  }
}
