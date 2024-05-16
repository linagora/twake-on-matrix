import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';

class GetClientsInitialUIState extends Success {
  @override
  List<Object?> get props => [];
}

class GetClientsLoadingUIState extends Success {
  @override
  List<Object?> get props => [];
}

class GetClientsSuccessUIState extends Success {
  final List<TwakeChatPresentationAccount> multipleAccounts;

  const GetClientsSuccessUIState({
    required this.multipleAccounts,
  });

  bool get haveMultipleAccounts => multipleAccounts.length > 1;

  @override
  List<Object?> get props => [multipleAccounts];
}

class GetClientsFailureUIState extends Failure {
  final dynamic exception;

  const GetClientsFailureUIState({this.exception});

  @override
  List<Object?> get props => [exception];
}
