import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/ban_user_state.dart';
import 'package:fluffychat/domain/usecase/room/ban_user_interactor.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'ban_user_interactor_test.mocks.dart';

@GenerateMocks([User, MatrixException])
void main() {
  late BanUserInteractor interactor;
  late MockUser mockUser;

  setUp(() {
    interactor = BanUserInteractor();
    mockUser = MockUser();
  });

  group('BanUserInteractor', () {
    test(
      'should yield NoPermissionForBanFailure and NOT call user.ban() when !user.canBan',
      () async {
        // Arrange
        when(mockUser.canBan).thenReturn(false);

        // Act
        final result = interactor.execute(user: mockUser);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>().having(
              (r) => r.value,
              'value',
              isA<BanUserLoading>(),
            ),
            isA<Left<Failure, Success>>().having(
              (l) => l.value,
              'value',
              isA<NoPermissionForBanFailure>(),
            ),
            emitsDone,
          ]),
        );
        verifyNever(mockUser.ban());
      },
    );

    test(
      'should call user.ban() and yield BanUserSuccess when user.canBan is true',
      () async {
        // Arrange
        when(mockUser.canBan).thenReturn(true);
        when(mockUser.ban()).thenAnswer((_) async {});

        // Act
        final result = interactor.execute(user: mockUser);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>().having(
              (r) => r.value,
              'value',
              isA<BanUserLoading>(),
            ),
            isA<Right<Failure, Success>>().having(
              (r) => r.value,
              'value',
              isA<BanUserSuccess>(),
            ),
            emitsDone,
          ]),
        );
        verify(mockUser.ban()).called(1);
      },
    );

    test(
      'should yield NoPermissionForBanFailure when MatrixException is M_FORBIDDEN',
      () async {
        // Arrange
        when(mockUser.canBan).thenReturn(true);
        final mockException = MockMatrixException();
        when(mockException.error).thenReturn(MatrixError.M_FORBIDDEN);
        when(mockUser.ban()).thenThrow(mockException);

        // Act
        final result = interactor.execute(user: mockUser);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>().having(
              (r) => r.value,
              'value',
              isA<BanUserLoading>(),
            ),
            isA<Left<Failure, Success>>().having(
              (l) => l.value,
              'value',
              isA<NoPermissionForBanFailure>(),
            ),
            emitsDone,
          ]),
        );
      },
    );

    test(
      'should yield BanUserFailure when MatrixException is NOT M_FORBIDDEN',
      () async {
        // Arrange
        when(mockUser.canBan).thenReturn(true);
        final mockException = MockMatrixException();
        when(mockException.error).thenReturn(MatrixError.M_UNKNOWN);
        when(mockUser.ban()).thenThrow(mockException);

        // Act
        final result = interactor.execute(user: mockUser);

        // Assert
        await expectLater(
          result,
          emitsInOrder([
            isA<Right<Failure, Success>>().having(
              (r) => r.value,
              'value',
              isA<BanUserLoading>(),
            ),
            isA<Left<Failure, Success>>().having(
              (l) => l.value,
              'value',
              isA<BanUserFailure>(),
            ),
            emitsDone,
          ]),
        );
      },
    );

    test('should yield BanUserFailure for generic exceptions', () async {
      // Arrange
      when(mockUser.canBan).thenReturn(true);
      final exception = Exception('Something went wrong');
      when(mockUser.ban()).thenThrow(exception);

      // Act
      final result = interactor.execute(user: mockUser);

      // Assert
      await expectLater(
        result,
        emitsInOrder([
          isA<Right<Failure, Success>>().having(
            (r) => r.value,
            'value',
            isA<BanUserLoading>(),
          ),
          isA<Left<Failure, Success>>().having(
            (l) => l.value,
            'value',
            isA<BanUserFailure>(),
          ),
          emitsDone,
        ]),
      );
    });
  });
}
