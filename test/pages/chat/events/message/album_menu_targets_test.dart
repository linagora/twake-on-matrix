import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/events/message/album_menu_targets.dart';
import 'package:twake_chat/pages/chat/events/message/message_context_menu_action.dart';

void main() {
  const targets = AlbumMenuTargets();
  const album = ['first', 'middle', 'caption'];

  List<String> of(MessageContextMenuAction action) =>
      targets.of(action, album, pressed: 'middle');

  test('reply and pin go to the first image', () {
    expect(of(MessageContextMenuAction.reply), ['first']);
    expect(of(MessageContextMenuAction.pin), ['first']);
  });

  test('copy and edit go to the caption, on the last image', () {
    expect(of(MessageContextMenuAction.copy), ['caption']);
    expect(of(MessageContextMenuAction.edit), ['caption']);
  });

  test('select goes to the pressed image', () {
    expect(of(MessageContextMenuAction.select), ['middle']);
  });

  test('the other album actions go to every image', () {
    for (final action in [
      MessageContextMenuAction.selectAll,
      MessageContextMenuAction.forward,
      MessageContextMenuAction.report,
      MessageContextMenuAction.saveToGallery,
      MessageContextMenuAction.delete,
    ]) {
      expect(of(action), album, reason: action.name);
    }
  });

  test('an action that is not on the album menu has no target', () {
    for (final action in [
      MessageContextMenuAction.copyLink,
      MessageContextMenuAction.saveToDownload,
      MessageContextMenuAction.trySendAgain,
    ]) {
      expect(of(action), isEmpty, reason: action.name);
    }
  });
}
