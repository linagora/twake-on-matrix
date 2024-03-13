import 'package:matrix/matrix.dart';

extension EventStatusCustomExtension on EventStatus {
  bool get isAvailableToForwardEvent {
    return !isError && !isSending;
  }
}
