import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/model/verification/composite_name_validator.dart';
import 'package:twake_chat/domain/model/verification/new_name_request.dart';
import 'package:twake_chat/domain/model/verification/validator.dart';

class VerifyNameInteractor {
  Either<Failure, Success> execute(
    String? newName,
    List<Validator> listValidator,
  ) {
    try {
      return CompositeNameValidator(
        listValidator,
      ).validate(NewNameRequest(newName));
    } catch (exception) {
      return Left<Failure, Success>(VerifyNameFailure(exception));
    }
  }
}
