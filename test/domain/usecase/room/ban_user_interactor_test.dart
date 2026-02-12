import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:fluffychat/domain/usecase/room/ban_user_interactor.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'ban_user_interactor_test.mocks.dart';

@GenerateMocks([User, Room, Client, MatrixException, Event])
void main() {
  late BanUserInteractor interactor;
  late MockUser mockUser;
  late MockRoom mockRoom;
  late MockClient mockClient;

  setUp(() {
    interactor = BanUserInteractor();
    mockUser = MockUser();
    mockRoom = MockRoom();
    mockClient = MockClient();

    // Default room setup
    when(mockRoom.client).thenReturn(mockClient);
    when(mockRoom.id).thenReturn('!room:server.com');
  });

  group('BanUserInteractor', () {
    test(
        'should yield NoPermissionForBanFailure and NOT call user.ban() when !user.canBan',
        () async {
      // Arrange
      when(mockUser.canBan).thenReturn(false);

      // Act
      final result = interactor.execute(user: mockUser, room: mockRoom);

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          isA<Right<Failure, Success>>()
              .having((r) => r.value, 'value', isA<BanUserLoading>()),
          isA<Left<Failure, Success>>().having(
            (l) => l.value,
            'value',
            isA<NoPermissionForBanFailure>(),
          ),
          emitsDone,
        ]),
      );
      verifyNever(mockUser.ban());
    });

    test(
        'should call user.ban() and yield BanUserSuccess when user.canBan is true',
        () async {
      // Arrange
      when(mockUser.canBan).thenReturn(true);
      when(mockUser.powerLevel)
          .thenReturn(DefaultPowerLevelMember.member.powerLevel);
      when(mockUser.ban()).thenAnswer((_) async {});

      // Act
      final result = interactor.execute(user: mockUser, room: mockRoom);

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          isA<Right<Failure, Success>>()
              .having((r) => r.value, 'value', isA<BanUserLoading>()),
          isA<Right<Failure, Success>>()
              .having((r) => r.value, 'value', isA<BanUserSuccess>()),
          emitsDone,
        ]),
      );
      verify(mockUser.ban()).called(1);
    });

    test(
        'should yield NoPermissionForBanFailure when MatrixException is M_FORBIDDEN',
        () async {
      // Arrange
      when(mockUser.canBan).thenReturn(true);
      when(mockUser.powerLevel)
          .thenReturn(DefaultPowerLevelMember.member.powerLevel);
      final mockException = MockMatrixException();
      when(mockException.error).thenReturn(MatrixError.M_FORBIDDEN);
      when(mockUser.ban()).thenThrow(mockException);

      // Act
      final result = interactor.execute(user: mockUser, room: mockRoom);

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          isA<Right<Failure, Success>>()
              .having((r) => r.value, 'value', isA<BanUserLoading>()),
          isA<Left<Failure, Success>>().having(
            (l) => l.value,
            'value',
            isA<NoPermissionForBanFailure>(),
          ),
          emitsDone,
        ]),
      );
    });

    test('should yield BanUserFailure when MatrixException is NOT M_FORBIDDEN',
        () async {
      // Arrange
      when(mockUser.canBan).thenReturn(true);
      when(mockUser.powerLevel)
          .thenReturn(DefaultPowerLevelMember.member.powerLevel);
      final mockException = MockMatrixException();
      when(mockException.error).thenReturn(MatrixError.M_UNKNOWN);
      when(mockUser.ban()).thenThrow(mockException);

      // Act
      final result = interactor.execute(user: mockUser, room: mockRoom);

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          isA<Right<Failure, Success>>()
              .having((r) => r.value, 'value', isA<BanUserLoading>()),
          isA<Left<Failure, Success>>().having(
            (l) => l.value,
            'value',
            isA<BanUserFailure>(),
          ),
          emitsDone,
        ]),
      );
    });

    test('should yield BanUserFailure for generic exceptions', () async {
      // Arrange
      when(mockUser.canBan).thenReturn(true);
      when(mockUser.powerLevel)
          .thenReturn(DefaultPowerLevelMember.member.powerLevel);
      final exception = Exception('Something went wrong');
      when(mockUser.ban()).thenThrow(exception);

      // Act
      final result = interactor.execute(user: mockUser, room: mockRoom);

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          isA<Right<Failure, Success>>()
              .having((r) => r.value, 'value', isA<BanUserLoading>()),
          isA<Left<Failure, Success>>()
              .having((l) => l.value, 'value', isA<BanUserFailure>()),
          emitsDone,
        ]),
      );
    });

    group('Power Level Reduction', () {
      late MockEvent mockPowerLevelEvent;

      setUp(() {
        mockPowerLevelEvent = MockEvent();
      });

      test(
          'should reduce power level to member and ban user when user has moderator power level',
          () async {
        // Arrange
        final powerLevelContent = {
          'users': {
            '@user:server.com': DefaultPowerLevelMember.moderator.powerLevel,
          },
        };

        when(mockUser.canBan).thenReturn(true);
        when(mockUser.powerLevel)
            .thenReturn(DefaultPowerLevelMember.moderator.powerLevel);
        when(mockUser.id).thenReturn('@user:server.com');
        when(mockUser.ban()).thenAnswer((_) async {});
        when(mockRoom.getState(EventTypes.RoomPowerLevels))
            .thenReturn(mockPowerLevelEvent);
        when(mockPowerLevelEvent.content).thenReturn(powerLevelContent);
        when(
          mockClient.setRoomStateWithKey(any, any, any, any),
        ).thenAnswer((_) async => '');

        // Act
        final result = interactor.execute(user: mockUser, room: mockRoom);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserLoading>()),
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserSuccess>()),
            emitsDone,
          ]),
        );

        // Verify power level was reduced to member
        final captured = verify(
          mockClient.setRoomStateWithKey(
            '!room:server.com',
            EventTypes.RoomPowerLevels,
            '',
            captureAny,
          ),
        ).captured.single as Map<String, dynamic>;

        expect(captured['users'], isA<Map<String, dynamic>>());
        expect(
          (captured['users'] as Map<String, dynamic>)['@user:server.com'],
          equals(DefaultPowerLevelMember.member.powerLevel),
        );

        verify(mockUser.ban()).called(1);
      });

      test(
          'should reduce power level to member and ban user when user has admin power level',
          () async {
        // Arrange
        final powerLevelContent = {
          'users': {
            '@admin:server.com': DefaultPowerLevelMember.admin.powerLevel,
          },
        };

        when(mockUser.canBan).thenReturn(true);
        when(mockUser.powerLevel)
            .thenReturn(DefaultPowerLevelMember.admin.powerLevel);
        when(mockUser.id).thenReturn('@admin:server.com');
        when(mockUser.ban()).thenAnswer((_) async {});
        when(mockRoom.getState(EventTypes.RoomPowerLevels))
            .thenReturn(mockPowerLevelEvent);
        when(mockPowerLevelEvent.content).thenReturn(powerLevelContent);
        when(
          mockClient.setRoomStateWithKey(any, any, any, any),
        ).thenAnswer((_) async => '');

        // Act
        final result = interactor.execute(user: mockUser, room: mockRoom);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserLoading>()),
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserSuccess>()),
            emitsDone,
          ]),
        );

        // Verify power level was reduced to member
        final captured = verify(
          mockClient.setRoomStateWithKey(
            '!room:server.com',
            EventTypes.RoomPowerLevels,
            '',
            captureAny,
          ),
        ).captured.single as Map<String, dynamic>;

        expect(captured['users'], isA<Map<String, dynamic>>());
        expect(
          (captured['users'] as Map<String, dynamic>)['@admin:server.com'],
          equals(DefaultPowerLevelMember.member.powerLevel),
        );

        verify(mockUser.ban()).called(1);
      });

      test(
          'should skip power level reduction and ban user when power level state is null',
          () async {
        // Arrange
        when(mockUser.canBan).thenReturn(true);
        when(mockUser.powerLevel)
            .thenReturn(DefaultPowerLevelMember.moderator.powerLevel);
        when(mockUser.id).thenReturn('@mod:server.com');
        when(mockUser.ban()).thenAnswer((_) async {});
        when(mockRoom.getState(EventTypes.RoomPowerLevels)).thenReturn(null);

        // Act
        final result = interactor.execute(user: mockUser, room: mockRoom);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserLoading>()),
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserSuccess>()),
            emitsDone,
          ]),
        );

        // Verify power level was NOT changed (to avoid overwriting server data)
        verifyNever(
          mockClient.setRoomStateWithKey(
            any,
            any,
            any,
            any,
          ),
        );

        // But ban still happened
        verify(mockUser.ban()).called(1);
      });

      test(
          'should NOT reduce power level when user has regular member power level',
          () async {
        // Arrange
        when(mockUser.canBan).thenReturn(true);
        when(mockUser.powerLevel)
            .thenReturn(DefaultPowerLevelMember.member.powerLevel);
        when(mockUser.ban()).thenAnswer((_) async {});

        // Act
        final result = interactor.execute(user: mockUser, room: mockRoom);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserLoading>()),
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserSuccess>()),
            emitsDone,
          ]),
        );

        // Verify power level was NOT changed
        verifyNever(
          mockClient.setRoomStateWithKey(
            any,
            any,
            any,
            any,
          ),
        );

        verify(mockUser.ban()).called(1);
      });

      test('should NOT reduce power level when user has guest power level',
          () async {
        // Arrange
        when(mockUser.canBan).thenReturn(true);
        when(mockUser.powerLevel)
            .thenReturn(DefaultPowerLevelMember.guest.powerLevel);
        when(mockUser.ban()).thenAnswer((_) async {});

        // Act
        final result = interactor.execute(user: mockUser, room: mockRoom);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserLoading>()),
            isA<Right<Failure, Success>>()
                .having((r) => r.value, 'value', isA<BanUserSuccess>()),
            emitsDone,
          ]),
        );

        // Verify power level was NOT changed
        verifyNever(
          mockClient.setRoomStateWithKey(
            any,
            any,
            any,
            any,
          ),
        );

        verify(mockUser.ban()).called(1);
      });
    });
  });
}
