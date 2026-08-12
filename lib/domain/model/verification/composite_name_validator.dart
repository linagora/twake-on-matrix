import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/model/verification/new_name_request.dart';
import 'package:twake_chat/domain/model/verification/validator.dart';
import 'package:twake_chat/domain/model/extensions/list_validator_extension.dart';

class CompositeNameValidator extends Validator<NewNameRequest> {
  final List<Validator> _listValidator;

  CompositeNameValidator(this._listValidator);

  @override
  Either<Failure, Success> validate(NewNameRequest value) {
    return _listValidator.isNotEmpty
        ? _listValidator.getValidatorNameViewState(value)
        : Right<Failure, Success>(VerifyNameSuccessViewState());
  }
}
