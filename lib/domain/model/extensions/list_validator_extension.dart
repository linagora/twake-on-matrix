import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/model/verification/new_name_request.dart';
import 'package:twake_chat/domain/model/verification/validator.dart';

extension ListValidatorExtension on List<Validator> {
  Either<Failure, Success> getValidatorNameViewState(
    NewNameRequest newNameRequest,
  ) {
    for (final validator in this) {
      final either = validator.validate(newNameRequest);
      if (either.isLeft()) {
        return either;
      }
    }
    return Right<Failure, Success>(VerifyNameSuccessViewState());
  }
}
