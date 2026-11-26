import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/voice_message/entities/shown_message.dart';
import 'package:twake_chat/domain/voice_message/exceptions/voice_message_exception.dart';
import 'package:twake_chat/domain/voice_message/usecases/find_next_voice_message_use_case.provider.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';

part 'voice_autoplay_controller.freezed.dart';
part 'voice_autoplay_controller.g.dart';

@freezed
sealed class VoiceAutoplayState with _$VoiceAutoplayState {
  const factory VoiceAutoplayState.idle() = VoiceAutoplayIdle;

  /// [eventId] played to its end: the screen answers with what it shows.
  /// [run] tells two ends of the same message apart.
  const factory VoiceAutoplayState.ended(String eventId, int run) =
      VoiceAutoplayEnded;

  /// The screen plays [eventId], unless the user started another audio.
  const factory VoiceAutoplayState.next(String eventId) = VoiceAutoplayNext;
}

/// Chains the voice messages of a chat screen, the room's or one of its
/// threads ([threadRootId]): when one ends, the next message plays if it is a
/// voice message too. Lives as long as that screen.
@riverpod
class VoiceAutoplayController extends _$VoiceAutoplayController {
  var _run = 0;

  @override
  VoiceAutoplayState build(String roomId, String? threadRootId) =>
      const VoiceAutoplayState.idle();

  void voiceMessageEnded(String eventId) {
    if (!ref.mounted) return;
    state = VoiceAutoplayState.ended(eventId, ++_run);
  }

  /// The screen is gone, or a message that ended since then started its own
  /// run.
  bool _isOver(int run) => !ref.mounted || run != _run;

  /// [shown] is what the screen shows, oldest first.
  Future<void> findNext(
    String eventId, {
    required List<ShownMessage> shown,
  }) async {
    if (!ref.mounted) return;
    final run = _run;
    state = const VoiceAutoplayState.idle();
    try {
      final next = await ref
          .read(findNextVoiceMessageUseCaseProvider)
          .execute(
            roomId: roomId,
            eventId: eventId,
            threadRootId: threadRootId,
            shown: shown,
          );
      if (_isOver(run) || next == null) return;
      state = VoiceAutoplayState.next(next);
    } on FindNextVoiceMessageException catch (error, stackTrace) {
      if (!ref.mounted) return;
      ref.read(reportFailureProvider)(
        error,
        stackTrace,
        'VoiceAutoplayController::findNext',
      );
    }
  }
}
