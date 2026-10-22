import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/app_state/settings/update_profile_failure.dart';
import 'package:twake_chat/domain/app_state/settings/update_profile_success.dart';
import 'package:twake_chat/domain/usecase/settings/update_profile_interactor.dart';

import 'update_profile_interactor_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  group('UpdateProfileInteractor', () {
    const String userId = '@alice:example.org';
    late UpdateProfileInteractor interactor;
    late MockClient client;

    setUp(() {
      interactor = UpdateProfileInteractor();
      client = MockClient();
      when(client.userID).thenReturn(userId);
      when(client.setProfileField(any, any, any)).thenAnswer((_) async => {});
    });

    test(
      'should clear the avatar with an empty string when deleting it',
      () async {
        // Arrange: default stubs from setUp

        // Act
        final states = await interactor
            .execute(client: client, isDeleteAvatar: true)
            .toList();

        // Assert
        verify(
          client.setProfileField(userId, 'avatar_url', {'avatar_url': ''}),
        ).called(1);
        expect(
          states.last.getOrElse(() => throw StateError('failure')),
          isA<DeleteProfileSuccess>(),
        );
      },
    );

    test('should send the new avatar url when setting one', () async {
      // Arrange
      final Uri avatarUrl = Uri.parse('mxc://example.org/avatar');

      // Act
      final states = await interactor
          .execute(client: client, avatarUrl: avatarUrl)
          .toList();

      // Assert
      verify(
        client.setProfileField(userId, 'avatar_url', {
          'avatar_url': avatarUrl.toString(),
        }),
      ).called(1);
      expect(
        states.last.getOrElse(() => throw StateError('failure')),
        isA<UpdateProfileSuccess>(),
      );
    });

    test('should yield a failure when the server rejects the change', () async {
      // Arrange
      when(
        client.setProfileField(any, any, any),
      ).thenThrow(Exception('M_INVALID_PARAM'));

      // Act
      final states = await interactor
          .execute(client: client, isDeleteAvatar: true)
          .toList();

      // Assert
      expect(
        states.last.swap().getOrElse(() => throw StateError('success')),
        isA<UpdateProfileFailure>(),
      );
    });
  });
}
