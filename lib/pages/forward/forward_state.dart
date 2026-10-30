import 'package:freezed_annotation/freezed_annotation.dart';

part 'forward_state.freezed.dart';

@freezed
sealed class ForwardState with _$ForwardState {
  const factory ForwardState.selecting({
    @Default(<String>[]) List<String> selectedRoomIds,
  }) = ForwardSelecting;

  const factory ForwardState.sending({required List<String> selectedRoomIds}) =
      ForwardSending;

  const factory ForwardState.done({
    required List<String> selectedRoomIds,
    required int successCount,
    required int totalCount,
  }) = ForwardDone;
}
