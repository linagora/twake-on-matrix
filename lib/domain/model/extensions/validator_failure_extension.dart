import 'package:fluffychat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:fluffychat/domain/exception/verify_name_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

extension ValidatorFailureExtension on VerifyNameFailure {
  String getMessage(BuildContext context) {
    if (exception is NameWithSpaceOnlyException) {
      return L10n.of(context)!.this_field_cannot_be_blank;
    } else {
      return '';
    }
  }
}
