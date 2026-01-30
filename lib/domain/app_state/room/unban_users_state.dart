import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class UnbanUsersLoading extends Success {
  @override
  List<Object?> get props => [];
}

class UnbanUsersSuccess extends Success {
  const UnbanUsersSuccess();

  @override
  List<Object?> get props => [];
}

class UnbanUsersFailure extends Failure {
  final Map<User, Failure> failures;

  const UnbanUsersFailure({required this.failures});

  @override
  List<Object?> get props => [failures];
}
