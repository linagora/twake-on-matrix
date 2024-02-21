import 'package:fluffychat/presentation/model/pop_result.dart';

class ImageViewerArgument extends PopResult {
  final String? showInChatEventId;

  final String? roomId;

  ImageViewerArgument({
    this.showInChatEventId,
    this.roomId,
  });

  @override
  List<Object?> get props => [roomId, showInChatEventId];
}
