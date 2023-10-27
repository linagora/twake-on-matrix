import 'package:flutter/material.dart';

class FocusSuggestionController {
  List<Map<String, String?>> _suggestions = List.empty();

  List<Map<String, String?>> get suggestions => _suggestions;

  set suggestions(List<Map<String, String?>> suggestions) {
    _suggestions = suggestions;
    currentIndex.value = 0;
  }

  final currentIndex = ValueNotifier(0);

  void up() {
    currentIndex.value--;
    if (currentIndex.value < 0) {
      currentIndex.value = _suggestions.length - 1;
    }
  }

  void down() {
    currentIndex.value++;
    if (currentIndex.value >= _suggestions.length) {
      currentIndex.value = 0;
    }
  }

  void dispose() {
    currentIndex.dispose();
  }
}
