import 'package:flutter/foundation.dart';

enum DialogKeys {
  showConfirmAlertDialog,
  bootstrapBreakpointMobile,
  bootstrapBreakpointWebAndDesktop,
  initClientBreakpointMobile,
  initClientBreakpointWebAndDesktop;

  Key get key => Key('dialog.$name');

  ValueKey<String> get valueKey => ValueKey('dialog.$name');
}
