import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

enum MultipleAccountLoginType {
  firstLoggedIn,
  otherAccountLoggedIn,
}

class ClientLoginStateEvent with EquatableMixin {
  final Client client;
  final LoginState loginState;
  final MultipleAccountLoginType multipleAccountLoginType;

  ClientLoginStateEvent({
    required this.client,
    required this.loginState,
    required this.multipleAccountLoginType,
  });

  @override
  List<Object?> get props => [
        client,
        loginState,
        multipleAccountLoginType,
      ];
}
