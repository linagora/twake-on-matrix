import 'dart:io';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/profile/datasources/own_profile_datasource.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/event/twake_inapp_event_types.dart';

final class OwnProfileDatasourceImpl implements OwnProfileDatasource {
  const OwnProfileDatasourceImpl(this._client);

  final Client? _client;

  Client get _activeClient =>
      _client ?? (throw const NoActiveClientException());

  @override
  Future<Uri> uploadAvatar(AvatarUpload avatar) async {
    final bytes = switch (avatar) {
      AvatarFromBytes(:final bytes) => bytes,
      AvatarFromFile(:final path) => await File(path).readAsBytes(),
    };
    // The SDK refuses a file over the server's m.upload.size before sending.
    return _activeClient.uploadContent(
      bytes,
      filename: avatar.name,
      contentType: avatar.mimeType,
    );
  }

  @override
  Future<void> setAvatar(Uri? avatarUrl) async {
    final client = _activeClient;
    await client.setProfileField(client.userID!, 'avatar_url', {
      // Servers reject null; an empty string clears the avatar.
      'avatar_url': avatarUrl?.toString() ?? '',
    });
  }

  @override
  Future<void> setDisplayName(String displayName) async {
    final client = _activeClient;
    await client.setProfileField(client.userID!, 'displayname', {
      'displayname': displayName,
    });
  }

  @override
  void announce(AccountProfile profile) {
    _activeClient.onAccountData.add(
      BasicEvent(
        type: TwakeInappEventTypes.uploadAvatarEvent,
        content: Profile(
          userId: profile.userId,
          displayName: profile.displayName,
          avatarUrl: profile.avatarUrl,
        ).toJson(),
      ),
    );
  }
}
