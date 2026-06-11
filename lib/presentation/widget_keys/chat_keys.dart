import 'package:flutter/foundation.dart';

enum ChatKeys {
  leaveChatButton(
    Key('chat.leaveChatButton'),
    ValueKey('chat.leaveChatButton'),
  ),
  actionsMobileAndTablet(
    Key('chat.actionsMobileAndTablet'),
    ValueKey('chat.actionsMobileAndTablet'),
  ),
  actionsWebAndDesktop(
    Key('chat.actionsWebAndDesktop'),
    ValueKey('chat.actionsWebAndDesktop'),
  ),
  composerTypeAhead(
    Key('chat.composerTypeAhead'),
    ValueKey('chat.composerTypeAhead'),
  ),
  mediaPickerTypeAhead(
    Key('chat.mediaPickerTypeAhead'),
    ValueKey('chat.mediaPickerTypeAhead'),
  ),
  draftComposerTypeAhead(
    Key('chat.draftComposerTypeAhead'),
    ValueKey('chat.draftComposerTypeAhead'),
  ),
  draftMediaPickerTypeAhead(
    Key('chat.draftMediaPickerTypeAhead'),
    ValueKey('chat.draftMediaPickerTypeAhead'),
  ),
  sendFileDialogTypeAhead(
    Key('chat.sendFileDialogTypeAhead'),
    ValueKey('chat.sendFileDialogTypeAhead'),
  ),
  eventListCenter(
    Key('chat.eventListCenter'),
    ValueKey('chat.eventListCenter'),
  ),
  invitationSelectionMobileAndTablet(
    Key('chat.invitationSelectionMobileAndTablet'),
    ValueKey('chat.invitationSelectionMobileAndTablet'),
  ),
  invitationSelectionWebAndDesktop(
    Key('chat.invitationSelectionWebAndDesktop'),
    ValueKey('chat.invitationSelectionWebAndDesktop'),
  ),
  forwardSelectionMobileAndTablet(
    Key('chat.forwardSelectionMobileAndTablet'),
    ValueKey('chat.forwardSelectionMobileAndTablet'),
  ),
  forwardSelectionWebAndDesktop(
    Key('chat.forwardSelectionWebAndDesktop'),
    ValueKey('chat.forwardSelectionWebAndDesktop'),
  );

  const ChatKeys(this.key, this.valueKey);

  final Key key;
  final ValueKey<String> valueKey;
}
