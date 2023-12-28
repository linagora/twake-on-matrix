import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';

class TwakeChatPresentationAccount extends TwakePresentationAccount {
  const TwakeChatPresentationAccount({
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
}
