import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/exception/verify_name_exception.dart';
import 'package:fluffychat/domain/model/verification/new_name_request.dart';
import 'package:fluffychat/domain/model/verification/validator.dart';

class NameWithSpaceOnlyValidator extends Validator<NewNameRequest> {
  @override
  Either<Failure, Success> validate(NewNameRequest value) {
    if (value.value != null &&
        value.value!.isNotEmpty &&
        value.value!.trim().isEmpty) {
      return const Left<Failure, Success>(
        VerifyNameFailure(NameWithSpaceOnlyException()),
      );
    } else {
      return Right<Failure, Success>(VerifyNameSuccessViewState());
    }
  }
}
