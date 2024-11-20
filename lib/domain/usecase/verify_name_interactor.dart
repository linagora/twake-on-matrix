import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/model/verification/composite_name_validator.dart';
import 'package:fluffychat/domain/model/verification/new_name_request.dart';
import 'package:fluffychat/domain/model/verification/validator.dart';

class VerifyNameInteractor {
  Either<Failure, Success> execute(
    String? newName,
    List<Validator> listValidator,
  ) {
    try {
      return CompositeNameValidator(listValidator)
          .validate(NewNameRequest(newName));
    } catch (exception) {
      return Left<Failure, Success>(VerifyNameFailure(exception));
    }
  }
}
