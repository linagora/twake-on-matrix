import 'package:flutter/foundation.dart';

enum DialogKeys {
  showConfirmAlertDialog,
  bootstrapBreakpointMobile,
  bootstrapBreakpointWebAndDesktop,
  initClientBreakpointMobile,
  initClientBreakpointWebAndDesktop;

  Key get key => Key(name);

  ValueKey<String> get valueKey => ValueKey(name);
}
