import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class FocusSuggestionController {
  List<Map<String, String?>> _suggestions = List.empty();

  List<Map<String, String?>> get suggestions => _suggestions;

  set suggestions(List<Map<String, String?>> suggestions) {
    _suggestions = suggestions;
    currentIndex.value = 0;
  }

  bool get hasSuggestions => _suggestions.isNotEmpty;

  final currentIndex = ValueNotifier(0);

  void up() {
    try {
      currentIndex.value--;
      if (currentIndex.value < 0) {
        currentIndex.value = _suggestions.length - 1;
      }
    } on FlutterError catch (error) {
      Logs().e(
        "FocusSuggestionController()::up(): FlutterError: $error",
      );
    }
  }

  void down() {
    try {
      currentIndex.value++;
      if (currentIndex.value >= _suggestions.length) {
        currentIndex.value = 0;
      }
    } on FlutterError catch (error) {
      Logs().e(
        "FocusSuggestionController()::down(): FlutterError: $error",
      );
    }
  }

  void dispose() {
    currentIndex.dispose();
  }
}
