import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/model/verification/new_name_request.dart';
import 'package:fluffychat/domain/model/verification/validator.dart';

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
