import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum PhoneNumberContextMenuActions {
  call,
  copy;

  String getTitle(BuildContext context) {
    switch (this) {
      case PhoneNumberContextMenuActions.call:
        return L10n.of(context)!.callViaCarrier;
      case PhoneNumberContextMenuActions.copy:
        return L10n.of(context)!.copyNumber;
    }
  }

  IconData getIconData() {
    switch (this) {
      case PhoneNumberContextMenuActions.call:
        return Icons.call_outlined;
      case PhoneNumberContextMenuActions.copy:
        return Icons.content_copy_outlined;
    }
  }
}
