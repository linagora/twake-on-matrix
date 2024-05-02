import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class PublicRoomSuccess extends Success {
  final List<PublicRoomsChunk>? publicRoomsChunk;

  const PublicRoomSuccess({this.publicRoomsChunk});

  @override
  List<Object?> get props => [publicRoomsChunk];
}

class PublicRoomFailed extends Failure {
  final dynamic exception;

  const PublicRoomFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
