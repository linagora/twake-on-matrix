import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/usecase/verify_name_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';

import '../model/verification/composite_name_validator_test.mocks.dart';

void main() {
  group('VerifyNameInteractor', () {
    late MockValidator mockValidator1;
    late MockValidator mockValidator2;
    late VerifyNameInteractor interactor;
    setUp(() {
      mockValidator1 = MockValidator();
      mockValidator2 = MockValidator();
      interactor = VerifyNameInteractor();
    });
    test('returns VerifyNameViewState success when all validators pass', () {
      const newName = 'ValidName';

      when(mockValidator1.validate(any))
          .thenReturn(Right(VerifyNameSuccessViewState()));
      when(mockValidator2.validate(any))
          .thenReturn(Right(VerifyNameSuccessViewState()));

      final result =
          interactor.execute(newName, [mockValidator1, mockValidator2]);

      expect(result, isA<Right>());
      expect(result, Right<Failure, Success>(VerifyNameSuccessViewState()));
      verify(mockValidator1.validate(any)).called(1);
      verify(mockValidator2.validate(any)).called(1);
    });

    test('returns failure when one of the validators fails', () {
      final mockValidator1 = MockValidator();
      final mockValidator2 = MockValidator();
      final interactor = VerifyNameInteractor();
      const newName = 'InvalidName';

      when(mockValidator1.validate(any))
          .thenReturn(Right(VerifyNameSuccessViewState()));
      when(mockValidator2.validate(any))
          .thenReturn(const Left(VerifyNameFailure('Name is not valid')));

      final result =
          interactor.execute(newName, [mockValidator1, mockValidator2]);

      expect(result, isA<Left>());
      verify(mockValidator1.validate(any)).called(1);
      verify(mockValidator2.validate(any)).called(1);
    });

    test('returns VerifyNameFailure when an exception occurs', () {
      final mockValidator = MockValidator();
      final interactor = VerifyNameInteractor();
      const newName = 'ValidName';

      // Mock a validator to throw an exception
      when(mockValidator.validate(any))
          .thenThrow(Exception('Validation failed'));

      final result = interactor.execute(newName, [mockValidator]);

      expect(result, isA<Left>());
      expect((result as Left).value, isA<VerifyNameFailure>());
    });
  });
}
