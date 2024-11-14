import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/model/verification/composite_name_validator.dart';
import 'package:fluffychat/domain/model/verification/validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/model/verification/new_name_request.dart';
import 'composite_name_validator_test.mocks.dart';

@GenerateMocks([Validator])
void main() {
  group('CompositeNameValidator', () {
    late CompositeNameValidator compositeValidator;
    late MockValidator mockValidator1;
    late MockValidator mockValidator2;
    setUp(() {
      compositeValidator = CompositeNameValidator([]);
      mockValidator1 = MockValidator();
      mockValidator2 = MockValidator();
    });
    test('returns VerifyNameViewState when list of validators is empty', () {
      final newNameRequest = NewNameRequest('ValidName');

      final result = compositeValidator.validate(newNameRequest);

      expect(result, isA<Right>());
      expect(result, Right<Failure, Success>(VerifyNameSuccessViewState()));
    });

    test(
        'applies multiple validators and returns failure if any validator fails',
        () {
      final newNameRequest = NewNameRequest('InvalidName');

      when(mockValidator1.validate(newNameRequest))
          .thenReturn(Right(VerifyNameSuccessViewState()));
      when(mockValidator2.validate(newNameRequest))
          .thenReturn(const Left(VerifyNameFailure("Invalid name")));

      final compositeValidator =
          CompositeNameValidator([mockValidator1, mockValidator2]);

      final result = compositeValidator.validate(newNameRequest);

      expect(result, isA<Left>());
      verify(mockValidator1.validate(newNameRequest)).called(1);
      verify(mockValidator2.validate(newNameRequest)).called(1);
    });

    test('returns success if all validators pass', () {
      final mockValidator1 = MockValidator();
      final mockValidator2 = MockValidator();
      final newNameRequest = NewNameRequest('ValidName');

      when(mockValidator1.validate(newNameRequest))
          .thenReturn(Right(VerifyNameSuccessViewState()));
      when(mockValidator2.validate(newNameRequest))
          .thenReturn(Right(VerifyNameSuccessViewState()));

      final compositeValidator =
          CompositeNameValidator([mockValidator1, mockValidator2]);

      final result = compositeValidator.validate(newNameRequest);

      expect(result, isA<Right>());
      verify(mockValidator1.validate(newNameRequest)).called(1);
      verify(mockValidator2.validate(newNameRequest)).called(1);
    });
  });
}
