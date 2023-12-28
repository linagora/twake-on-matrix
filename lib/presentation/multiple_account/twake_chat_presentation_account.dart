import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';
import 'package:matrix/matrix.dart';

class TwakeChatPresentationAccount extends TwakePresentationAccount {
  final Client clientAccount;

  const TwakeChatPresentationAccount({
    required this.clientAccount,
    required String accountName,
    required String accountId,
    required Widget avatar,
    required AccountActiveStatus accountActiveStatus,
  }) : super(
          accountName: accountName,
          accountId: accountId,
          avatar: avatar,
          accountActiveStatus: accountActiveStatus,
        );

  @override
  List<Object?> get props => [
        clientAccount,
        accountName,
        accountId,
        avatar,
        accountActiveStatus,
      ];
}
