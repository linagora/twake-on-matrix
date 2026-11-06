import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:twake_chat/domain/public_rooms/usecases/fetch_joinable_public_rooms_usecase.dart';

/// The search text once the typing stops, trimmed; null under two letters.
class PublicGroupsSearchTerm extends ValueNotifier<String?> {
  PublicGroupsSearchTerm(this._textController) : super(null) {
    _textController.addListener(_onTextChanged);
  }

  static const debounceDuration = Duration(milliseconds: 300);

  final TextEditingController _textController;

  Timer? _debounce;

  void _onTextChanged() {
    _debounce?.cancel();
    final text = _textController.text.trim();
    if (text.length < FetchJoinablePublicRoomsUseCase.minSearchLength) {
      value = null;
      return;
    }
    _debounce = Timer(debounceDuration, () => value = text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.removeListener(_onTextChanged);
    super.dispose();
  }
}
