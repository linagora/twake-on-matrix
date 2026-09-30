import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/usecase/room/create_new_group_chat_interactor.dart';

import 'create_new_group_chat_interactor_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  late MockClient mockClient;
  late CreateNewGroupChatInteractor interactor;

  setUp(() {
    mockClient = MockClient();
    interactor = CreateNewGroupChatInteractor();
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
    ).thenAnswer((_) async => '!room:example.com');
  });

  Future<void> createGroup(CreateNewGroupChatRequest request) => interactor
      .execute(matrixClient: mockClient, createNewGroupChatRequest: request)
      .drain<void>();

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

  group('CreateNewGroupChatInteractor.execute', () {
    test(
      'execute_whenPublicAndServerLimited_createsAnUnencryptedUnfederatedPublicRoom',
      () async {
        // Arrange
        const request = CreateNewGroupChatRequest(
          groupName: 'Paris Business',
          enableEncryption: true,
          isPublic: true,
          isServerLimited: true,
        );

        // Act
        await createGroup(request);

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
      'execute_whenPublicWithoutServerLimit_createsAFederatedPublicRoom',
      () async {
        // Arrange
        const request = CreateNewGroupChatRequest(
          groupName: 'Open Lab',
          isPublic: true,
        );

        // Act
        await createGroup(request);

        // Assert
        verifyRoomCreatedWith(
          enableEncryption: false,
          preset: CreateRoomPreset.publicChat,
          visibility: Visibility.public,
          federated: true,
        );
      },
    );

    test('execute_whenPrivate_ignoresTheServerLimit', () async {
      // Arrange
      const request = CreateNewGroupChatRequest(
        groupName: 'Team',
        enableEncryption: true,
        isServerLimited: true,
      );

      // Act
      await createGroup(request);

      // Assert
      verifyRoomCreatedWith(
        enableEncryption: true,
        preset: CreateRoomPreset.privateChat,
        visibility: null,
        federated: true,
      );
    });
  });
}
