import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class PreSearchRecentContactsSuccess extends Success {
  final List<User> users;

  const PreSearchRecentContactsSuccess({required this.users});

  @override
  List<Object?> get props => [users];
}

class PreSearchRecentContactsFailed extends Failure {
  final dynamic exception;

  const PreSearchRecentContactsFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class PreSearchRecentContactsEmpty extends Failure {
  const PreSearchRecentContactsEmpty();

  @override
  List<Object?> get props => [];
}
