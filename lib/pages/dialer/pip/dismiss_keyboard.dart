import 'package:flutter/material.dart';

void dismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}
