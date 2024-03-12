import 'package:flutter/material.dart';

void dismissKeyboard(BuildContext context) {
  if (ModalRoute.of(context)?.isCurrent == true) {
    if (FocusManager.instance.primaryFocus?.hasFocus == true) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
