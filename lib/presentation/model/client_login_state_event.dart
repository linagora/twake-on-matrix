import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/matrix.dart';

part 'client_login_state_event.freezed.dart';

enum MultipleAccountLoginType {
  firstLoggedIn,
  otherAccountLoggedIn,

  /// The login succeeded on the server but a step after it failed (storing
  /// the account, ToM or federation set-up, the switch); the login was undone
  /// and [ClientLoginStateEvent.error] says why. It is terminal: the screen
  /// shows the error and the user starts again on a fresh client.
  loginFailed,

  /// The login failed and undoing it failed too: the account or its storage
  /// may still exist. The cleanup is retried; the screen shows the error like
  /// a failed login, but nothing was cleaned up yet.
  cleanupFailed,
}

extension MultipleAccountLoginTypeFailure on MultipleAccountLoginType {
  /// True for the two events that end a login with an error.
  bool get isFailure =>
      this == MultipleAccountLoginType.loginFailed ||
      this == MultipleAccountLoginType.cleanupFailed;
}

@freezed
abstract class ClientLoginStateEvent with _$ClientLoginStateEvent {
  const factory ClientLoginStateEvent({
    required Client client,
    required LoginState loginState,
    required MultipleAccountLoginType multipleAccountLoginType,
    Object? error,
  }) = _ClientLoginStateEvent;
}
