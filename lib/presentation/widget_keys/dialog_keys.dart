import 'package:flutter/foundation.dart';

enum DialogKeys {
  showConfirmAlertDialog(
    Key('dialog.showConfirmAlertDialog'),
    ValueKey('dialog.showConfirmAlertDialog'),
  ),
  bootstrapBreakpointMobile(
    Key('dialog.bootstrapBreakpointMobile'),
    ValueKey('dialog.bootstrapBreakpointMobile'),
  ),
  bootstrapBreakpointWebAndDesktop(
    Key('dialog.bootstrapBreakpointWebAndDesktop'),
    ValueKey('dialog.bootstrapBreakpointWebAndDesktop'),
  ),
  initClientBreakpointMobile(
    Key('dialog.initClientBreakpointMobile'),
    ValueKey('dialog.initClientBreakpointMobile'),
  ),
  initClientBreakpointWebAndDesktop(
    Key('dialog.initClientBreakpointWebAndDesktop'),
    ValueKey('dialog.initClientBreakpointWebAndDesktop'),
  );

  const DialogKeys(this.key, this.valueKey);

  final Key key;
  final ValueKey<String> valueKey;
}
