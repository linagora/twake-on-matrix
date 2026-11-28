import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.provider.dart';

part 'scribe_controller.g.dart';

@riverpod
class ScribeController extends _$ScribeController {
  @override
  bool build(String roomId) => false;

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
