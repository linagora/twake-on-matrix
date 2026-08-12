import 'package:twake_chat/domain/app_state/validator/verify_name_view_state.dart';
import 'package:twake_chat/domain/exception/verify_name_exception.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

extension ValidatorFailureExtension on VerifyNameFailure {
  String getMessage(BuildContext context) {
    if (exception is NameWithSpaceOnlyException ||
        exception is EmptyNameException) {
      return L10n.of(context)!.thisFieldCannotBeBlank;
    } else {
      return '';
    }
  }
}
