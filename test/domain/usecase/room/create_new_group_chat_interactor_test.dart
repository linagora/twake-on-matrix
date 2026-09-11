import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:twake_chat/domain/exception/room/can_not_create_new_group_chat_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/usecase/room/create_new_group_chat_interactor.dart';

import 'create_new_group_chat_interactor_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  late CreateNewGroupChatInteractor interactor;
  late MockClient mockClient;
  late MockRoom mockRoom;

  const testRoomId = '!room:example.com';

  /// Matches the loading state every run starts with.
  final emitsLoading = predicate(
    (dynamic value) =>
        value is Right && value.value is CreateNewGroupChatLoading,
  );

  Matcher emitsFailureWith<T>() => predicate(
    (dynamic value) =>
        value is Left &&
        value.value is CreateNewGroupChatFailed &&
        (value.value as CreateNewGroupChatFailed).exception is T,
  );

  void stubRawCreateRoom({Object? throws}) {
    final stub = when(
      mockClient.request(
        any,
        any,
        data: anyNamed('data'),
        contentType: anyNamed('contentType'),
        query: anyNamed('query'),
      ),
    );
    throws != null
        ? stub.thenThrow(throws)
        : stub.thenAnswer((_) async => {'room_id': testRoomId});
  }

  setUp(() {
    mockClient = MockClient();
    mockRoom = MockRoom();
    interactor = CreateNewGroupChatInteractor();

    when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
    when(
      mockClient.createGroupChat(
        groupName: anyNamed('groupName'),
        enableEncryption: anyNamed('enableEncryption'),
        preset: anyNamed('preset'),
        initialState: anyNamed('initialState'),
        powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
      ),
    ).thenAnswer((_) async => testRoomId);
  });

  group('CreateNewGroupChatInteractor', () {
    test('execute_whenRequestIsNotAFeed_usesCreateGroupChat', () async {
      // Arrange
      const request = CreateNewGroupChatRequest(groupName: 'My group');

      // Act
      final result = interactor.execute(
        matrixClient: mockClient,
        createNewGroupChatRequest: request,
      );

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          emitsLoading,
          const Right(
            CreateNewGroupChatSuccess(
              roomId: testRoomId,
              userIds: [],
              groupName: 'My group',
            ),
          ),
        ]),
      );
      verify(
        mockClient.createGroupChat(
          groupName: 'My group',
          enableEncryption: anyNamed('enableEncryption'),
          preset: anyNamed('preset'),
          initialState: anyNamed('initialState'),
          powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
        ),
      ).called(1);
      verifyNever(
        mockClient.request(
          any,
          any,
          data: anyNamed('data'),
          contentType: anyNamed('contentType'),
          query: anyNamed('query'),
        ),
      );
    });

    test('execute_whenRequestIsAFeed_usesTheRawCreateRoomEndpoint', () async {
      // Arrange
      stubRawCreateRoom();
      const request = CreateNewGroupChatRequest(
        groupName: 'My feed',
        isFeed: true,
      );

      // Act
      final result = interactor.execute(
        matrixClient: mockClient,
        createNewGroupChatRequest: request,
      );

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          emitsLoading,
          const Right(
            CreateNewGroupChatSuccess(
              roomId: testRoomId,
              userIds: [],
              groupName: 'My feed',
            ),
          ),
        ]),
      );
      verify(
        mockClient.request(
          RequestType.POST,
          '/client/v3/createRoom',
          data: anyNamed('data'),
          contentType: anyNamed('contentType'),
          query: anyNamed('query'),
        ),
      ).called(1);
      verifyNever(
        mockClient.createGroupChat(
          groupName: anyNamed('groupName'),
          enableEncryption: anyNamed('enableEncryption'),
          preset: anyNamed('preset'),
          initialState: anyNamed('initialState'),
          powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
        ),
      );
    });

    test(
      'execute_whenFeedPresetIsRejectedByTheHomeserver_failsWithFeedNotSupported',
      () async {
        // Arrange
        stubRawCreateRoom(
          // Verbatim response of an unpatched Synapse, from
          // synapse/handlers/room.py::_room_preset_config
          throws: MatrixException.fromJson({
            'errcode': 'M_BAD_JSON',
            'error': "'${FeedConfig.preset}' is not a valid preset",
          }),
        );
        const request = CreateNewGroupChatRequest(
          groupName: 'My feed',
          isFeed: true,
        );

        // Act
        final result = interactor.execute(
          matrixClient: mockClient,
          createNewGroupChatRequest: request,
        );

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            emitsLoading,
            emitsFailureWith<FeedNotSupportedByHomeserverException>(),
          ]),
        );
      },
    );

    test(
      'execute_whenFeedCreationFailsForAnotherReason_keepsTheGenericFailure',
      () async {
        // Arrange
        stubRawCreateRoom(
          throws: MatrixException.fromJson({
            'errcode': 'M_LIMIT_EXCEEDED',
            'error': 'Too many requests',
          }),
        );
        const request = CreateNewGroupChatRequest(
          groupName: 'My feed',
          isFeed: true,
        );

        // Act
        final result = interactor.execute(
          matrixClient: mockClient,
          createNewGroupChatRequest: request,
        );

        // Assert
        await expectLater(
          result,
          emitsInOrder([emitsLoading, emitsFailureWith<MatrixException>()]),
        );
      },
    );

    test(
      'execute_whenGroupCreationHitsThePresetWording_staysAGenericFailure',
      () async {
        // Arrange — the feed-specific mapping must not leak onto groups
        when(
          mockClient.createGroupChat(
            groupName: anyNamed('groupName'),
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
            initialState: anyNamed('initialState'),
            powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
          ),
        ).thenThrow(
          MatrixException.fromJson({
            'errcode': 'M_UNKNOWN',
            'error': 'invalid preset',
          }),
        );
        const request = CreateNewGroupChatRequest(groupName: 'My group');

        // Act
        final result = interactor.execute(
          matrixClient: mockClient,
          createNewGroupChatRequest: request,
        );

        // Assert
        await expectLater(
          result,
          emitsInOrder([emitsLoading, emitsFailureWith<MatrixException>()]),
        );
      },
    );
  });
}
