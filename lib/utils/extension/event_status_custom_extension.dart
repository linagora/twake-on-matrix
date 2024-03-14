import 'package:matrix/matrix.dart';

extension EventStatusCustomExtension on EventStatus {
  bool get isAvailable {
    return !isError && !isSending;
  }
}
