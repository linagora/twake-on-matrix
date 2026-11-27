import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_line.freezed.dart';

enum CallLineOutcome { answered, missed, canceled }

/// A call as one line of the chat, for one reader, read from the
/// `app.twake.chat.call` event its caller writes when leaving
/// (DECISION.md D31).
@freezed
abstract class CallLine with _$CallLine {
  const factory CallLine({
    required bool isOutgoing,
    required bool isVideo,
    required CallLineOutcome outcome,

    /// From the answer to the end, for an answered call only.
    Duration? duration,
  }) = _CallLine;

  /// Null when [content] is no valid call line.
  static CallLine? fromContent(
    Map<String, Object?> content, {
    required bool isOwn,
  }) {
    final intent = content['intent'];
    final endedTs = content['ended_ts'];
    final answeredTs = content['answered_ts'];
    if (!_isIntent(intent) || endedTs is! int) return null;
    if (!_isValidAnswer(answeredTs, endedTs)) return null;
    final answeredAt = answeredTs as int?;
    return CallLine(
      isOutgoing: isOwn,
      isVideo: intent == 'video',
      outcome: _outcomeOf(isAnswered: answeredAt != null, isOwn: isOwn),
      duration: answeredAt == null
          ? null
          : Duration(milliseconds: endedTs - answeredAt),
    );
  }

  static bool _isIntent(Object? intent) =>
      intent == 'audio' || intent == 'video';

  static bool _isValidAnswer(Object? answeredTs, int endedTs) {
    if (answeredTs == null) return true;
    return answeredTs is int && answeredTs <= endedTs;
  }

  static CallLineOutcome _outcomeOf({
    required bool isAnswered,
    required bool isOwn,
  }) {
    if (isAnswered) return CallLineOutcome.answered;
    return isOwn ? CallLineOutcome.canceled : CallLineOutcome.missed;
  }
}
