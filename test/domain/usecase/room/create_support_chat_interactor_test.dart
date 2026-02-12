import 'package:dartz/dartz.dart';
import 'package:fluffychat/data/model/media/upload_file_json.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
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

@GenerateMocks([
  Client,
  MediaAPI,
  PowerLevelManager,
  DiscoveryInformation,
  Room,
])
void main() {
  late CreateSupportChatInteractor interactor;
  late MockClient mockClient;
  late MockMediaAPI mockMediaAPI;
  late MockPowerLevelManager mockPowerLevelManager;
  late MockDiscoveryInformation mockDiscovery;
  late MockRoom mockRoom;

  const testUserId = '@test:example.com';
  const testRoomId = '!room123:example.com';
  const testSupportContactId = '@support:example.com';
  const testAvatarUrl = 'mxc://example.com/avatar123';

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockClient = MockClient();
    mockMediaAPI = MockMediaAPI();
    mockPowerLevelManager = MockPowerLevelManager();
    mockDiscovery = MockDiscoveryInformation();
    mockRoom = MockRoom();

    GetIt.instance.registerSingleton<MediaAPI>(mockMediaAPI);
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
          when(
            mockClient.getWellknown(),
          ).thenAnswer((_) async => mockDiscovery);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenThrow(Exception('No account data found'));
          when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
            (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
          );
          when(
            mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
          ).thenReturn({});
          when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
          when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
          when(
            mockClient.createGroupChat(
              groupName: anyNamed('groupName'),
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          ).thenAnswer((_) async => testRoomId);
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
          when(
            mockRoom.invite(testSupportContactId),
          ).thenAnswer((_) async => {});
          when(
            mockRoom.setPower(testSupportContactId, 100),
          ).thenAnswer((_) async => 'event_id');
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

          final result = interactor.execute(mockClient);

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

          verify(mockClient.getWellknown()).called(1);
          verify(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).called(1);
          verify(
            mockClient.createGroupChat(
              groupName: 'Support Twake Workplace',
              enableEncryption: false,
              preset: CreateRoomPreset.trustedPrivateChat,
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          ).called(1);
          verify(mockRoom.invite(testSupportContactId)).called(1);
          verify(mockRoom.setPower(testSupportContactId, 100)).called(1);
          verify(mockRoom.setPower(testUserId, 0)).called(1);
          verify(mockRoom.setFavourite(true)).called(1);
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
          when(
            mockClient.getWellknown(),
          ).thenAnswer((_) async => mockDiscovery);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenAnswer((_) async => {'createdSupportChat': testRoomId});
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

          final result = interactor.execute(mockClient);

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

          verify(mockClient.getWellknown()).called(1);
          verify(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).called(1);
          verify(mockClient.getRoomById(testRoomId)).called(1);
          verifyNever(
            mockClient.createGroupChat(
              groupName: anyNamed('groupName'),
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          );
        },
      );

      test(
        'should continue when account data throws exception but room does not exist',
        () async {
          when(mockClient.userID).thenReturn(testUserId);
          when(
            mockClient.getWellknown(),
          ).thenAnswer((_) async => mockDiscovery);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenThrow(Exception('No account data'));
          when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
            (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
          );
          when(
            mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
          ).thenReturn({});
          when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
          when(mockPowerLevelManager.getUserPowerLevel()).thenReturn(0);
          when(
            mockClient.createGroupChat(
              groupName: anyNamed('groupName'),
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          ).thenAnswer((_) async => testRoomId);
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
          when(
            mockRoom.invite(testSupportContactId),
          ).thenAnswer((_) async => {});
          when(
            mockRoom.setPower(testSupportContactId, 100),
          ).thenAnswer((_) async => 'event_id');
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

          final result = interactor.execute(mockClient);

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
            mockClient.createGroupChat(
              groupName: 'Support Twake Workplace',
              enableEncryption: false,
              preset: CreateRoomPreset.trustedPrivateChat,
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          ).called(1);
          verify(mockRoom.invite(testSupportContactId)).called(1);
          verify(mockRoom.setPower(testSupportContactId, 100)).called(1);
          verify(mockRoom.setPower(testUserId, 0)).called(1);
        },
      );
    });

    group('execute - failure cases', () {
      test(
        'should fail when support contact is not found in well-known',
        () async {
          when(
            mockClient.getWellknown(),
          ).thenAnswer((_) async => mockDiscovery);
          when(
            mockDiscovery.additionalProperties,
          ).thenReturn({WellKnownMixin.twakeChatKey: {}});

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

          verify(mockClient.getWellknown()).called(1);
          verifyNever(
            mockClient.createGroupChat(
              groupName: anyNamed('groupName'),
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          );
        },
      );

      test('should fail when support contact is not a string', () async {
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {WellKnownMixin.supportContact: 123},
        });

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

        verify(mockClient.getWellknown()).called(1);
      });

      test('should fail when user ID is null', () async {
        when(mockClient.userID).thenReturn(null);
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });

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

        verify(mockClient.getWellknown()).called(1);
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

      test('should fail when avatar upload fails', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(
          mockMediaAPI.uploadFileWeb(file: anyNamed('file')),
        ).thenThrow(Exception('Upload failed'));

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

        verify(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).called(1);
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

      test('should fail when room creation fails', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
          (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
        );
        when(
          mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
        ).thenReturn({});
        when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
        when(
          mockClient.createGroupChat(
            groupName: anyNamed('groupName'),
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
            initialState: anyNamed('initialState'),
            powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
          ),
        ).thenThrow(Exception('Room creation failed'));

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

        verify(
          mockClient.createGroupChat(
            groupName: 'Support Twake Workplace',
            enableEncryption: false,
            preset: CreateRoomPreset.trustedPrivateChat,
            initialState: anyNamed('initialState'),
            powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
          ),
        ).called(1);
      });

      test('should fail when room is not found after creation', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
          (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
        );
        when(
          mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
        ).thenReturn({});
        when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
        when(
          mockClient.createGroupChat(
            groupName: anyNamed('groupName'),
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
            initialState: anyNamed('initialState'),
            powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
          ),
        ).thenAnswer((_) async => testRoomId);
        when(mockClient.getRoomById(testRoomId)).thenReturn(null);

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

        verify(mockClient.getRoomById(testRoomId)).called(1);
      });

      test('should fail when setFavourite fails', () async {
        when(mockClient.userID).thenReturn(testUserId);
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
          (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
        );
        when(
          mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
        ).thenReturn({});
        when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
        when(
          mockClient.createGroupChat(
            groupName: anyNamed('groupName'),
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
            initialState: anyNamed('initialState'),
            powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
          ),
        ).thenAnswer((_) async => testRoomId);
        when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
        when(mockRoom.invite(testSupportContactId)).thenAnswer((_) async => {});
        when(
          mockRoom.setPower(testSupportContactId, 100),
        ).thenAnswer((_) async => 'event_id');
        when(
          mockRoom.setFavourite(true),
        ).thenThrow(Exception('setFavourite failed'));

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

        verify(mockRoom.invite(testSupportContactId)).called(1);
        verify(mockRoom.setPower(testSupportContactId, 100)).called(1);
        verify(mockRoom.setFavourite(true)).called(1);
      });
    });

    group('execute - cleanup on failure', () {
      test(
        'should leave room and clear account data when creation fails',
        () async {
          when(mockClient.userID).thenReturn(testUserId);
          when(
            mockClient.getWellknown(),
          ).thenAnswer((_) async => mockDiscovery);
          when(mockDiscovery.additionalProperties).thenReturn({
            WellKnownMixin.twakeChatKey: {
              WellKnownMixin.supportContact: testSupportContactId,
            },
          });
          when(
            mockClient.getAccountData(testUserId, 'app.twake.support_room'),
          ).thenThrow(Exception('No account data found'));
          when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
            (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
          );
          when(
            mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
          ).thenReturn({});
          when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
          when(
            mockClient.createGroupChat(
              groupName: anyNamed('groupName'),
              enableEncryption: anyNamed('enableEncryption'),
              preset: anyNamed('preset'),
              initialState: anyNamed('initialState'),
              powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
            ),
          ).thenAnswer((_) async => testRoomId);
          when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
          when(
            mockRoom.invite(testSupportContactId),
          ).thenAnswer((_) async => {});
          when(
            mockRoom.setPower(testSupportContactId, 100),
          ).thenAnswer((_) async => 'event_id');
          when(
            mockRoom.setFavourite(true),
          ).thenThrow(Exception('setFavourite failed'));
          when(mockClient.leaveRoom(testRoomId)).thenAnswer((_) async => {});
          when(
            mockClient.setAccountData(testUserId, 'app.twake.support_room', {
              'createdSupportChat': null,
            }),
          ).thenAnswer((_) async => {});

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
        when(mockClient.getWellknown()).thenAnswer((_) async => mockDiscovery);
        when(mockDiscovery.additionalProperties).thenReturn({
          WellKnownMixin.twakeChatKey: {
            WellKnownMixin.supportContact: testSupportContactId,
          },
        });
        when(
          mockClient.getAccountData(testUserId, 'app.twake.support_room'),
        ).thenThrow(Exception('No account data found'));
        when(mockMediaAPI.uploadFileWeb(file: anyNamed('file'))).thenAnswer(
          (_) async => const UploadFileResponse(contentUri: testAvatarUrl),
        );
        when(
          mockPowerLevelManager.getDefaultPowerLevelEventForMember(),
        ).thenReturn({});
        when(mockPowerLevelManager.getAdminPowerLevel()).thenReturn(100);
        when(
          mockClient.createGroupChat(
            groupName: anyNamed('groupName'),
            enableEncryption: anyNamed('enableEncryption'),
            preset: anyNamed('preset'),
            initialState: anyNamed('initialState'),
            powerLevelContentOverride: anyNamed('powerLevelContentOverride'),
          ),
        ).thenAnswer((_) async => testRoomId);
        when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);
        when(mockRoom.invite(testSupportContactId)).thenAnswer((_) async => {});
        when(
          mockRoom.setPower(testSupportContactId, 100),
        ).thenAnswer((_) async => 'event_id');
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

        verify(mockClient.leaveRoom(testRoomId)).called(1);
      });
    });
  });
}
