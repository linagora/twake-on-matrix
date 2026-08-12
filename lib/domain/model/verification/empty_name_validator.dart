import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/exception/verify_name_exception.dart';
import 'package:twake_chat/domain/model/verification/new_name_request.dart';
import 'package:twake_chat/domain/model/verification/validator.dart';

class EmptyNameValidator extends Validator<NewNameRequest> {
  @override
  Either<Failure, Success> validate(NewNameRequest value) {
    if (value.value == null || value.value!.isEmpty) {
      return const Left<Failure, Success>(
        VerifyNameFailure(EmptyNameException()),
      );
    } else {
      return Right<Failure, Success>(VerifyNameSuccessViewState());
    }
  }
}
