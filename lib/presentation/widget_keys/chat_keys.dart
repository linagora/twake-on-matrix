import 'package:flutter/foundation.dart';

enum ChatKeys {
  leaveChatButton,
  actionsMobileAndTablet,
  actionsWebAndDesktop,
  composerTypeAhead,
  mediaPickerTypeAhead,
  draftComposerTypeAhead,
  draftMediaPickerTypeAhead,
  sendFileDialogTypeAhead,
  eventListCenter,
  invitationSelectionMobileAndTablet,
  invitationSelectionWebAndDesktop,
  forwardSelectionMobileAndTablet,
  forwardSelectionWebAndDesktop;

  Key get key => Key(name);

  ValueKey<String> get valueKey => ValueKey(name);
}
