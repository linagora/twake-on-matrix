import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/new_group/new_group_datasource_impl.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';

import 'new_group_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  const roomId = '!room:example.com';
  const userId = '@bob:example.com';

  late MockClient mockClient;
  late NewGroupDatasourceImpl datasource;

  setUp(() {
    mockClient = MockClient();
    datasource = NewGroupDatasourceImpl(mockClient);
    when(
      mockClient.createGroupChat(
        groupName: anyNamed('groupName'),
        enableEncryption: anyNamed('enableEncryption'),
        preset: anyNamed('preset'),
        initialState: anyNamed('initialState'),
        visibility: anyNamed('visibility'),
        federated: anyNamed('federated'),
        powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
      ),
    ).thenAnswer((_) async => roomId);
  });

  void verifyRoomCreatedWith({
    required bool? enableEncryption,
    required CreateRoomPreset preset,
    required Visibility? visibility,
    required bool federated,
  }) {
    verify(
      mockClient.createGroupChat(
        groupName: anyNamed('groupName'),
        enableEncryption: enableEncryption,
        preset: preset,
        initialState: anyNamed('initialState'),
        visibility: visibility,
        federated: federated,
        powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
      ),
    ).called(1);
  }

  MatrixException matrixError(String errcode, {int? retryAfterMs}) =>
      MatrixException.fromJson({
        'errcode': errcode,
        'error': errcode == 'M_BAD_STATE'
            ? 'Cannot invite user who was banned'
            : 'error',
        'retry_after_ms': ?retryAfterMs,
      });

  group('NewGroupDatasourceImpl.createGroup in a space', () {
    const spaceId = '!space:other.org';
    const request = CreateNewGroupChatRequest(
      groupName: 'Dev',
      parentSpaceId: spaceId,
    );

    List<StateEvent> initialState() =>
        verify(
              mockClient.createGroupChat(
                groupName: anyNamed('groupName'),
                enableEncryption: anyNamed('enableEncryption'),
                preset: anyNamed('preset'),
                initialState: captureAnyNamed('initialState'),
                visibility: anyNamed('visibility'),
                federated: anyNamed('federated'),
                powerLevelContentOverride: anyNamed(
                  'powerLevelContentOverride',
                ),
              ),
            ).captured.single
            as List<StateEvent>;

    setUp(() {
      when(mockClient.userID).thenReturn('@me:own.org');
    });

    test('createGroup_always_namesItsSpaceAndOpensToItsMembers', () async {
      await datasource.createGroup(request);

      final state = initialState();
      final parent = state.singleWhere((e) => e.type == EventTypes.SpaceParent);
      expect(parent.stateKey, spaceId);
      expect(parent.content, {
        'via': ['other.org', 'own.org'],
        'canonical': true,
      });
      expect(
        state.singleWhere((e) => e.type == EventTypes.RoomJoinRules).content,
        {
          'join_rule': 'restricted',
          'allow': [
            {'type': 'm.room_membership', 'room_id': spaceId},
          ],
        },
      );
    });

    test('createGroup_whenPublic_isNotRestricted', () async {
      await datasource.createGroup(request.copyWith(isPublic: true));

      expect(
        initialState().where((e) => e.type == EventTypes.RoomJoinRules),
        isEmpty,
      );
    });

    test('createGroup_always_listsItInTheSpace', () async {
      await datasource.createGroup(request);

      verify(
        mockClient.setRoomStateWithKey(spaceId, EventTypes.SpaceChild, roomId, {
          'via': ['example.com', 'own.org'],
        }),
      ).called(1);
    });

    test('createGroup_whenSuggested_saysSo', () async {
      await datasource.createGroup(request.copyWith(isSuggested: true));

      verify(
        mockClient.setRoomStateWithKey(spaceId, EventTypes.SpaceChild, roomId, {
          'via': ['example.com', 'own.org'],
          'suggested': true,
        }),
      ).called(1);
    });

    test('createGroup_whenSpaceRefuses_removesTheRoom', () async {
      when(mockClient.setRoomStateWithKey(any, any, any, any)).thenThrow(
        MatrixException.fromJson({'errcode': 'M_FORBIDDEN', 'error': 'no'}),
      );

      await expectLater(
        datasource.createGroup(request),
        throwsA(isA<SpaceForbiddenException>()),
      );
      verify(mockClient.leaveRoom(roomId)).called(1);
      verify(mockClient.forgetRoom(roomId)).called(1);
    });

    test('createGroup_whenListingGetsNoAnswer_returnsTheRoom', () async {
      when(
        mockClient.setRoomStateWithKey(any, any, any, any),
      ).thenThrow(TimeoutException('no answer'));

      expect(await datasource.createGroup(request), roomId);
      verifyNever(mockClient.leaveRoom(roomId));
    });

    test('createGroup_whenUserMayNotAdd_createsNothing', () async {
      when(mockClient.onRoomState).thenReturn(CachedStreamController());
      final space = Room(id: spaceId, client: mockClient);
      space.setState(
        Event(
          type: EventTypes.RoomPowerLevels,
          content: {'state_default': 50},
          stateKey: '',
          eventId: r'$pl',
          senderId: '@admin:other.org',
          originServerTs: DateTime(2020),
          room: space,
        ),
      );
      when(mockClient.getRoomById(spaceId)).thenReturn(space);

      await expectLater(
        datasource.createGroup(request),
        throwsA(isA<SpaceForbiddenException>()),
      );
      verifyNever(
        mockClient.createGroupChat(
          groupName: anyNamed('groupName'),
          enableEncryption: anyNamed('enableEncryption'),
          preset: anyNamed('preset'),
          initialState: anyNamed('initialState'),
          visibility: anyNamed('visibility'),
          federated: anyNamed('federated'),
          powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
        ),
      );
    });

    test('createGroup_whenNoSpace_listsNothing', () async {
      await datasource.createGroup(
        const CreateNewGroupChatRequest(groupName: 'Dev'),
      );

      verifyNever(mockClient.setRoomStateWithKey(any, any, any, any));
    });
  });

  group('NewGroupDatasourceImpl.createGroup', () {
    test(
      'createGroup_always_setsTheAvatarHistoryAndPowerLevelsLikeBefore',
      () async {
        // Act
        await datasource.createGroup(
          const CreateNewGroupChatRequest(
            groupName: 'Team',
            enableEncryption: true,
            urlAvatar: 'mxc://example.com/avatar',
          ),
        );

        // Assert
        final captured = verify(
          mockClient.createGroupChat(
            groupName: anyNamed('groupName'),
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
            initialState: captureAnyNamed('initialState'),
            visibility: anyNamed('visibility'),
            federated: anyNamed('federated'),
            powerLevelContentOverride: captureAnyNamed(
              'powerLevelContentOverride',
            ),
          ),
        ).captured;
        final initialState = captured[0] as List<StateEvent>;
        expect(initialState.map((event) => event.toJson()), [
          {
            'type': EventTypes.RoomAvatar,
            'content': {'url': 'mxc://example.com/avatar'},
            'state_key': '',
          },
          {
            'type': EventTypes.HistoryVisibility,
            'content': {'history_visibility': 'joined'},
            'state_key': '',
          },
        ]);
        expect(captured[1], {
          'events': {
            EventTypes.RoomPinnedEvents: 10,
            EventTypes.RoomName: 80,
            EventTypes.RoomAvatar: 80,
            EventTypes.RoomMember: 10,
            EventTypes.RoomTopic: 80,
          },
          'invite': 80,
          'kick': 80,
        });
      },
    );

    test(
      'createGroup_whenPublicWithoutServerAcl_createsAnUnencryptedUnfederatedPublicRoom',
      () async {
        // Act
        await datasource.createGroup(
          const CreateNewGroupChatRequest(
            groupName: 'Paris Business',
            enableEncryption: true,
            isPublic: true,
          ),
        );

        // Assert
        verifyRoomCreatedWith(
          enableEncryption: false,
          preset: CreateRoomPreset.publicChat,
          visibility: Visibility.public,
          federated: false,
        );
      },
    );

    test(
      'createGroup_whenPublicWithServerAcl_createsAPublicRoomWithoutMFederate',
      () async {
        // Act
        await datasource.createGroup(
          const CreateNewGroupChatRequest(
            groupName: 'Open Lab',
            isPublic: true,
            isServerAclEnabled: true,
          ),
        );

        // Assert
        verifyRoomCreatedWith(
          enableEncryption: false,
          preset: CreateRoomPreset.publicChat,
          visibility: Visibility.public,
          federated: true,
        );
      },
    );

    test('createGroup_whenPrivate_createsAPrivateRoom', () async {
      // Act
      await datasource.createGroup(
        const CreateNewGroupChatRequest(
          groupName: 'Team',
          enableEncryption: true,
        ),
      );

      // Assert
      verifyRoomCreatedWith(
        enableEncryption: true,
        preset: CreateRoomPreset.privateChat,
        visibility: null,
        federated: true,
      );
    });
  });

  group('NewGroupDatasourceImpl.inviteUser', () {
    test('inviteUser_whenNoClient_throwsAStateError', () async {
      // Act & Assert
      await expectLater(
        const NewGroupDatasourceImpl(
          null,
        ).inviteUser(roomId: roomId, userId: userId),
        throwsStateError,
      );
    });

    test('inviteUser_whenRateLimitedOnce_retriesThenSucceeds', () async {
      // Arrange
      var calls = 0;
      when(mockClient.inviteUser(roomId, userId)).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw matrixError('M_LIMIT_EXCEEDED', retryAfterMs: 1);
      });

      // Act
      await datasource.inviteUser(roomId: roomId, userId: userId);

      // Assert
      expect(calls, 2);
    });

    test(
      'inviteUser_whenAlwaysRateLimited_givesUpAfterThreeAttempts',
      () async {
        // Arrange
        when(
          mockClient.inviteUser(roomId, userId),
        ).thenThrow(matrixError('M_LIMIT_EXCEEDED', retryAfterMs: 1));

        // Act & Assert
        await expectLater(
          datasource.inviteUser(roomId: roomId, userId: userId),
          throwsA(isA<GenericInviteException>()),
        );
        verify(mockClient.inviteUser(roomId, userId)).called(3);
      },
    );

    test('inviteUser_whenBanned_throwsUserBannedWithoutRetry', () async {
      // Arrange
      when(
        mockClient.inviteUser(roomId, userId),
      ).thenThrow(matrixError('M_BAD_STATE'));

      // Act & Assert
      await expectLater(
        datasource.inviteUser(roomId: roomId, userId: userId),
        throwsA(isA<UserBannedException>()),
      );
      verify(mockClient.inviteUser(roomId, userId)).called(1);
    });

    test('inviteUser_whenNotAMatrixError_throwsGeneric', () async {
      // Arrange
      when(
        mockClient.inviteUser(roomId, userId),
      ).thenThrow(Exception('socket closed'));

      // Act & Assert
      await expectLater(
        datasource.inviteUser(roomId: roomId, userId: userId),
        throwsA(
          isA<GenericInviteException>().having(
            (e) => e.message,
            'message',
            contains('socket closed'),
          ),
        ),
      );
    });
  });
}
