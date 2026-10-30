import 'package:freezed_annotation/freezed_annotation.dart';

part 'forward_result.freezed.dart';

@freezed
abstract class ForwardResult with _$ForwardResult {
  const factory ForwardResult({
    required int successCount,
    required int totalCount,
  }) = _ForwardResult;
}
