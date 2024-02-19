import 'package:flutter/foundation.dart';

class ListNotifier<T> extends ChangeNotifier
    implements ValueListenable<List<T>> {
  final List<T> _elements;

  ListNotifier(this._elements);

  bool remove(T value) {
    final result = _elements.remove(value);
    if (result) {
      notifyListeners();
      return result;
    }
    return result;
  }

  void add(T value) {
    _elements.add(value);
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  void update(T oldValue, T newValue) {
    final index = _elements.indexOf(oldValue);
    if (index >= 0 && index < _elements.length) {
      _elements[index] = newValue;
      notifyListeners();
    }
  }

  @override
  List<T> get value => _elements;
}
