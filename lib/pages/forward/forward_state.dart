import 'package:freezed_annotation/freezed_annotation.dart';

part 'forward_state.freezed.dart';

@freezed
sealed class ForwardState with _$ForwardState {
  const factory ForwardState.idle() = ForwardIdle;

  const factory ForwardState.sending() = ForwardSending;

  const factory ForwardState.done({
    required int successCount,
    required int totalCount,
  }) = ForwardDone;
}
