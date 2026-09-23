import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';

part 'contact_source_value.freezed.dart';

/// A raw snapshot of a contact as provided by a single source.
///
/// Values are never merged at this level: [ContactResolutionPolicy] is the
/// only place that knows how to combine them into a [UnifiedContact].
@freezed
abstract class ContactSourceValue with _$ContactSourceValue {
  const factory ContactSourceValue({
    required ContactSourceKind kind,
    String? displayName,
    String? avatarUrl,
    @Default(<String>[]) List<String> emails,
    @Default(<String>[]) List<String> phones,
    DateTime? updatedAt,
  }) = _ContactSourceValue;
}
