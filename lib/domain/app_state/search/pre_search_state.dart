import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class PreSearchRecentContactsSuccess extends Success {
  final List<Room> rooms;

  const PreSearchRecentContactsSuccess({required this.rooms});

  @override
  List<Object?> get props => [rooms];
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
