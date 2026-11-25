import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.provider.dart';

part 'scribe_controller.g.dart';

/// The Scribe of one room's composer. The state is true while a draft is
/// being rewritten: the composer then shows progress and holds the send.
@riverpod
class ScribeController extends _$ScribeController {
  @override
  bool build(String roomId) => false;

  /// The draft with [prompt] applied. A second call while one runs is a
  /// programmer error: the button is hidden meanwhile.
  ///
  /// Throws the `ScribeException`s and `DriveException`s of
  /// `RewriteDraftUseCase.execute`.
  Future<String> rewrite({
    required ScribeRoom room,
    required ScribePrompt prompt,
    required String draft,
  }) async {
    if (state) throw StateError('A rewrite is already running');
    state = true;
    try {
      return await ref
          .read(rewriteDraftUseCaseProvider)
          .execute(room: room, prompt: prompt, draft: draft);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
