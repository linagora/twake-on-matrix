import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_presence.freezed.dart';

enum PresenceStatus { online, away, offline }

@freezed
abstract class PersonPresence with _$PersonPresence {
  const factory PersonPresence({
    required PresenceStatus status,
    DateTime? lastActiveAt,
    String? statusMessage,
  }) = _PersonPresence;
}
