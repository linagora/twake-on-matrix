import 'package:flutter/widgets.dart';

extension NavigatorStateExtension on NavigatorState {
  void popAllDialogs() {
    popUntil((route) => route is! RawDialogRoute);
  }
}
