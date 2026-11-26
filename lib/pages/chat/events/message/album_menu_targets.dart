import 'package:twake_chat/pages/chat/events/message/message_context_menu_action.dart';

/// Which events of an album a menu action acts on. An album is one message:
/// reply and pin go to its first image, copy and edit to its caption (the
/// last image), Start a thread to the last image, Select to the pressed image, and the rest to every image.
class AlbumMenuTargets {
  const AlbumMenuTargets();

  /// The actions of the album menu; any other action has no target.
  static const Map<MessageContextMenuAction, _Target> _targetOf = {
    MessageContextMenuAction.reply: _Target.first,
    MessageContextMenuAction.pin: _Target.first,
    MessageContextMenuAction.startThread: _Target.caption,
    MessageContextMenuAction.copy: _Target.caption,
    MessageContextMenuAction.edit: _Target.caption,
    MessageContextMenuAction.select: _Target.pressed,
    MessageContextMenuAction.selectAll: _Target.every,
    MessageContextMenuAction.forward: _Target.every,
    MessageContextMenuAction.report: _Target.every,
    MessageContextMenuAction.saveToGallery: _Target.every,
    MessageContextMenuAction.delete: _Target.every,
  };

  /// [album] is oldest first; [pressed] is the image under the finger.
  List<T> of<T>(
    MessageContextMenuAction action,
    List<T> album, {
    required T pressed,
  }) => switch (_targetOf[action]) {
    _Target.first => [album.first],
    _Target.caption => [album.last],
    _Target.pressed => [pressed],
    _Target.every => album,
    null => const [],
  };
}

enum _Target { first, caption, pressed, every }
