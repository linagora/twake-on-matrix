import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class ForwardMessageLoading extends Success {
  @override
  List<Object?> get props => [];
}

class ForwardMessageSuccess extends Success {
  final Room room;

  const ForwardMessageSuccess(this.room);
  @override
  List<Object?> get props => [room];
}

class ForwardMessageFailed extends Failure {
  final dynamic exception;

  const ForwardMessageFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class ForwardMessageIsShareFileState extends Success {
  final MatrixFile shareFile;
  final Room room;

  const ForwardMessageIsShareFileState({
    required this.shareFile,
    required this.room,
  });

  @override
  List<Object?> get props => [shareFile, room];
}
