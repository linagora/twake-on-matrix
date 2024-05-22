import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';
import 'package:matrix/matrix.dart';

class TwakeChatPresentationAccount extends TwakePresentationAccount {
  final Client clientAccount;

  const TwakeChatPresentationAccount({
    required this.clientAccount,
    required super.accountName,
    required super.accountId,
    required super.avatar,
    required super.accountActiveStatus,
  });

  @override
  List<Object?> get props => [
        clientAccount,
        accountName,
        accountId,
        avatar,
        accountActiveStatus,
      ];
}
