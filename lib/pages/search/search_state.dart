import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_state.freezed.dart';

@freezed
sealed class SearchState with _$SearchState {
  const factory SearchState.idle() = SearchIdle;

  const factory SearchState.opening() = SearchOpening;

  const factory SearchState.ownProfile() = SearchOwnProfile;

  const factory SearchState.room(String roomId) = SearchRoom;

  const factory SearchState.draft({
    required String matrixId,
    String? displayName,
  }) = SearchDraft;
}
