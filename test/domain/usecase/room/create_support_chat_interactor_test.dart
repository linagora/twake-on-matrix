import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/room/create_support_chat_state.dart';
import 'package:fluffychat/domain/usecase/room/create_support_chat_interactor.dart';
import 'package:fluffychat/presentation/mixins/wellknown_mixin.dart';
import 'package:fluffychat/utils/power_level_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'create_support_chat_interactor_test.mocks.dart';

@GenerateMocks([Client, PowerLevelManager, DiscoveryInformation, Room])
void main() {
  late CreateSupportChatInteractor interactor;
  late MockClient mockClient;
  late MockPowerLevelManager mockPowerLevelManager;
  late MockDiscoveryInformation mockDiscovery;
  late MockRoom mockRoom;

  const testUserId = '@test:example.com';
  const testRoomId = '!room123:example.com';
  const testSupportContactId = '@support:example.com';

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockClient = MockClient();
    mockPowerLevelManager = MockPowerLevelManager();
    mockDiscovery = MockDiscoveryInformation();
    mockRoom = MockRoom();

    GetIt.instance.registerSingleton<PowerLevelManager>(mockPowerLevelManager);

    interactor = const CreateSupportChatInteractor();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('CreateSupportChatInteractor', () {
    group('execute - success cases', () {
      test(
        'should create new support chat successfully when no existing room found',
        () async {
          when(mockClient.userID).thenReturn(testUserId);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenThrow(Exception('No account data found'));
          when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
          when(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
            ),
          ).thenAnswer((_) async => testRoomId);
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
          when(
            mockRoom.setPower(testUserId, 0),
          ).thenAnswer((_) async => 'event_id');
          when(mockRoom.setFavourite(true)).thenAnswer((_) async => {});
          when(
            mockClient.setAccountData(
              testUserId,
              'app.twake.support_room',
              any,
            ),
          ).thenAnswer((_) async => {});

          final result = interactor.execute(
            mockClient,
            cachedDiscovery: mockDiscovery,
          );

          await expectLater(
            result,
            emitsInOrder([
              predicate(
                (dynamic value) =>
                    value is Right && value.value is CreatingSupportChat,
              ),
              const Right(SupportChatCreated(roomId: testRoomId)),
            ]),
          );

          verify(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).called(1);
          verify(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: false,
              preset: CreateRoomPreset.privateChat,
            ),
          ).called(1);
          verify(mockRoom.setFavourite(true)).called(1);
          verify(mockRoom.setPower(testUserId, 0)).called(1);
          verify(
            mockClient.setAccountData(testUserId, 'app.twake.support_room', {
              'createdSupportChat': testRoomId,
            }),
          ).called(1);
        },
      );

      test(
        'should return existing support chat when room already exists',
        () async {
          when(mockClient.userID).thenReturn(testUserId);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenAnswer((_) async => {'createdSupportChat': testRoomId});
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

          final result = interactor.execute(
            mockClient,
            cachedDiscovery: mockDiscovery,
          );

          await expectLater(
            result,
            emitsInOrder([
              predicate(
                (dynamic value) =>
                    value is Right && value.value is CreatingSupportChat,
              ),
              const Right(SupportChatExisted(roomId: testRoomId)),
            ]),
          );

          verify(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).called(1);
          verify(mockClient.getRoomById(testRoomId)).called(1);
          verifyNever(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
            ),
          );
        },
      );

      test(
        'should continue when account data throws exception but room does not exist',
        () async {
          when(mockClient.userID).thenReturn(testUserId);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenThrow(Exception('No account data'));
          when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
          when(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
            ),
          ).thenAnswer((_) async => testRoomId);
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
          when(
            mockRoom.setPower(testUserId, 0),
          ).thenAnswer((_) async => 'event_id');
          when(mockRoom.setFavourite(true)).thenAnswer((_) async => {});
          when(
            mockClient.setAccountData(
              testUserId,
              'app.twake.support_room',
              any,
            ),
          ).thenAnswer((_) async => {});

          final result = interactor.execute(
            mockClient,
            cachedDiscovery: mockDiscovery,
          );

          await expectLater(
            result,
            emitsInOrder([
              predicate(
                (dynamic value) =>
                    value is Right && value.value is CreatingSupportChat,
              ),
              const Right(SupportChatCreated(roomId: testRoomId)),
            ]),
          );

          verify(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).called(1);
          verify(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: false,
              preset: CreateRoomPreset.privateChat,
            ),
          ).called(1);
          verify(mockRoom.setPower(testUserId, 0)).called(1);
        },
      );
    });

    group('execute - failure cases', () {
      test('should fail when cachedDiscovery is null', () async {
        final result = interactor.execute(mockClient);

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );
      });

      test(
        'should fail when support contact is not found in well-known',
        () async {
          when(
            mockDiscovery.additionalProperties,
          ).thenReturn({WellKnownMixin.twakeChatKey: {}});

          final result = interactor.execute(
            mockClient,
            cachedDiscovery: mockDiscovery,
          );

          await expectLater(
            result,
            emitsInOrder([
              predicate(
                (dynamic value) =>
                    value is Right && value.value is CreatingSupportChat,
              ),
              predicate(
                (dynamic value) =>
                    value is Left && value.value is CreateSupportChatFailed,
              ),
            ]),
          );

          verifyNever(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
            ),
          );
        },
      );

      test('should fail when support contact is not a string', () async {
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {WellKnownMixin.supportContact: 123},
        });

        final result = interactor.execute(
          mockClient,
          cachedDiscovery: mockDiscovery,
        );

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );
      });

      test('should fail when user ID is null', () async {
        when(mockClient.userID).thenReturn(null);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });

        final result = interactor.execute(
          mockClient,
          cachedDiscovery: mockDiscovery,
        );

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );

        verifyNever(
          mockClient.startDirectChat(
            testSupportContactId,
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
          ),
        );
      });

      test('should fail when room creation fails', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
        when(
          mockClient.startDirectChat(
            testSupportContactId,
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
          ),
        ).thenThrow(Exception('Room creation failed'));

        final result = interactor.execute(
          mockClient,
          cachedDiscovery: mockDiscovery,
        );

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );

        verify(
          mockClient.startDirectChat(
            testSupportContactId,
            enableEncryption: false,
            preset: CreateRoomPreset.privateChat,
          ),
        ).called(1);
      });

      test('should fail when room is not found after creation', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
        when(
          mockClient.startDirectChat(
            testSupportContactId,
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
          ),
        ).thenAnswer((_) async => testRoomId);
        when(mockClient.getRoomById(testRoomId)).thenReturn(null);

        final result = interactor.execute(
          mockClient,
          cachedDiscovery: mockDiscovery,
        );

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );

        verify(mockClient.getRoomById(testRoomId)).called(1);
      });

      test('should fail when setFavourite fails', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
        when(
          mockClient.startDirectChat(
            testSupportContactId,
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
          ),
        ).thenAnswer((_) async => testRoomId);
        when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
        when(
          mockClient.setAccountData(testUserId, 'app.twake.support_room', any),
        ).thenAnswer((_) async => {});
        when(
          mockRoom.setFavourite(true),
        ).thenThrow(Exception('setFavourite failed'));

        final result = interactor.execute(
          mockClient,
          cachedDiscovery: mockDiscovery,
        );

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );

        verify(mockRoom.setFavourite(true)).called(1);
      });
    });

    group('execute - cleanup on failure', () {
      test(
        'should leave room and clear account data when creation fails',
        () async {
          when(mockClient.userID).thenReturn(testUserId);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenThrow(Exception('No account data found'));
          when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
          when(
            mockClient.startDirectChat(
              testSupportContactId,
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
            ),
          ).thenAnswer((_) async => testRoomId);
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
          when(
            mockClient.setAccountData(
              testUserId,
              'app.twake.support_room',
              any,
            ),
          ).thenAnswer((_) async => {});
          when(
            mockRoom.setFavourite(true),
          ).thenThrow(Exception('setFavourite failed'));
          when(mockClient.leaveRoom(testRoomId)).thenAnswer((_) async => {});
          when(
            mockClient.setAccountData(testUserId, 'app.twake.support_room', {
              'createdSupportChat': null,
            }),
          ).thenAnswer((_) async => {});

          final result = interactor.execute(
            mockClient,
            cachedDiscovery: mockDiscovery,
          );

          await expectLater(
            result,
            emitsInOrder([
              predicate(
                (dynamic value) =>
                    value is Right && value.value is CreatingSupportChat,
              ),
              predicate(
                (dynamic value) =>
                    value is Left && value.value is CreateSupportChatFailed,
              ),
            ]),
          );

          verify(mockClient.leaveRoom(testRoomId)).called(1);
          verify(
            mockClient.setAccountData(testUserId, 'app.twake.support_room', {
              'createdSupportChat': null,
            }),
          ).called(1);
        },
      );

      test('should handle cleanup failure gracefully', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
        when(
          mockClient.startDirectChat(
            testSupportContactId,
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
          ),
        ).thenAnswer((_) async => testRoomId);
        when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
        when(
          mockClient.setAccountData(testUserId, 'app.twake.support_room', any),
        ).thenAnswer((_) async => {});
        when(
          mockRoom.setFavourite(true),
        ).thenThrow(Exception('setFavourite failed'));
        when(
          mockClient.leaveRoom(testRoomId),
        ).thenThrow(Exception('Leave room failed'));
        when(
          mockClient.setAccountData(testUserId, 'app.twake.support_room', {
            'createdSupportChat': null,
          }),
        ).thenThrow(Exception('Set account data failed'));

        final result = interactor.execute(
          mockClient,
          cachedDiscovery: mockDiscovery,
        );

        await expectLater(
          result,
          emitsInOrder([
            predicate(
              (dynamic value) =>
                  value is Right && value.value is CreatingSupportChat,
            ),
            predicate(
              (dynamic value) =>
                  value is Left && value.value is CreateSupportChatFailed,
            ),
          ]),
        );

        verify(mockClient.leaveRoom(testRoomId)).called(1);
      });
    });
  });
}
