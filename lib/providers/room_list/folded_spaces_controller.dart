import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/spaces/folded_spaces_datasource.provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

part 'folded_spaces_controller.g.dart';

/// The spaces folded in the room list, kept per account. A preference of this
/// device: no business rule, so no use case between it and its storage.
@riverpod
class FoldedSpacesController extends _$FoldedSpacesController {
  @override
  Future<Set<String>> build() async {
    final userId = ref.watch(activeUserIdProvider);
    if (userId == null) return const {};
    return ref.watch(foldedSpacesDatasourceProvider).read(userId);
  }

  Future<void> toggle(String spaceId) async {
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;
    // The stored choice first: writing before it is read would erase it.
    final folded = await future;
    if (!ref.mounted) return;
    final next = folded.contains(spaceId)
        ? folded.difference({spaceId})
        : {...folded, spaceId};
    state = AsyncData(next);
    await ref.read(foldedSpacesDatasourceProvider).write(userId, next);
  }
}
