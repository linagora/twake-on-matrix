import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/model/verification/new_name_request.dart';
import 'package:fluffychat/domain/model/verification/validator.dart';
import 'package:fluffychat/domain/model/extensions/list_validator_extension.dart';

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
