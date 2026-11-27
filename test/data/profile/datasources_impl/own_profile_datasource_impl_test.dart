import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/profile/datasources_impl/own_profile_datasource_impl.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/event/twake_inapp_event_types.dart';

class _FakeClient extends Fake implements Client {
  final List<(String, String, Map<String, Object?>)> profileWrites = [];
  final List<(int, String?, String?)> uploads = [];

  @override
  String? get userID => '@alice:server';

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();

  @override
  Future<Map<String, Object?>> setProfileField(
    String userId,
    String keyName,
    Map<String, Object?> body,
  ) async {
    profileWrites.add((userId, keyName, body));
    return {};
  }

  @override
  Future<Uri> uploadContent(
    Uint8List file, {
    String? filename,
    String? contentType,
  }) async {
    uploads.add((file.length, filename, contentType));
    return Uri.parse('mxc://server/uploaded');
  }
}

void main() {
  late _FakeClient client;

  setUp(() => client = _FakeClient());

  test('setAvatar_withNull_sendsAnEmptyString', () async {
    // Arrange
    final datasource = OwnProfileDatasourceImpl(client);

    // Act
    await datasource.setAvatar(null);

    // Assert
    final (userId, key, body) = client.profileWrites.single;
    expect((userId, key), ('@alice:server', 'avatar_url'));
    expect(body, {'avatar_url': ''});
  });

  test('setDisplayName_sendsTheName', () async {
    // Arrange
    final datasource = OwnProfileDatasourceImpl(client);

    // Act
    await datasource.setDisplayName('Alice');

    // Assert
    final (userId, key, body) = client.profileWrites.single;
    expect((userId, key), ('@alice:server', 'displayname'));
    expect(body, {'displayname': 'Alice'});
  });

  test('uploadAvatar_withBytes_uploadsThemWithNameAndType', () async {
    // Arrange
    final datasource = OwnProfileDatasourceImpl(client);

    // Act
    final uri = await datasource.uploadAvatar(
      AvatarUpload.fromBytes(
        bytes: Uint8List(3),
        name: 'a.png',
        mimeType: 'image/png',
      ),
    );

    // Assert
    expect(uri, Uri.parse('mxc://server/uploaded'));
    expect(client.uploads, [(3, 'a.png', 'image/png')]);
  });

  test('announce_addsTheUploadAvatarEvent', () async {
    // Arrange
    final datasource = OwnProfileDatasourceImpl(client);
    final events = <BasicEvent>[];
    final sub = client.onAccountData.stream.listen(events.add);
    addTearDown(sub.cancel);

    // Act
    datasource.announce(
      const AccountProfile(userId: '@alice:server', displayName: 'Alice'),
    );
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(events.single.type, TwakeInappEventTypes.uploadAvatarEvent);
    expect(events.single.content['display_name'], 'Alice');
  });

  test('setDisplayName_withoutActiveClient_throwsNoActiveClient', () {
    // Arrange
    const datasource = OwnProfileDatasourceImpl(null);

    // Act
    final result = datasource.setDisplayName('Alice');

    // Assert
    expect(result, throwsA(isA<NoActiveClientException>()));
  });
}
