import 'package:equatable/equatable.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:matrix/matrix.dart';

class FakeSendingFileInfo with EquatableMixin {
  final FileInfo fileInfo;

  final FakeImageEvent fakeImageEvent;

  final MessageType messageType;

  FakeSendingFileInfo({
    required this.fileInfo,
    required this.fakeImageEvent,
    required this.messageType,
  });

  @override
  List<Object?> get props => [fileInfo, fakeImageEvent, messageType];
}
