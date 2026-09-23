import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';

part 'unified_contact.freezed.dart';

/// The single identity projection consumed by every screen.
///
/// One entry per `matrixId`. It is a *read model*: it is derived from the
/// sources listed in [sources] and never replaces the Matrix SDK as the
/// owner of rooms, timelines or members.
@freezed
abstract class UnifiedContact with _$UnifiedContact {
  const UnifiedContact._();

  const factory UnifiedContact({
    required String matrixId,

    /// Directory / server resolved name (TOM UserInfo > TOM AddressBook >
    /// Matrix profile > Matrix room member).
    String? canonicalDisplayName,

    /// The user's local name from the device phonebook, when present.
    String? localAlias,

    String? avatarUrl,
    @Default(<String>[]) List<String> emails,
    @Default(<String>[]) List<String> phones,
    @Default(<ContactSourceValue>[]) List<ContactSourceValue> sources,

    /// Whether the contact is currently active (online / available).
    @Default(false) bool active,

    /// Which source produced [resolvedDisplayName].
    ContactSourceKind? prioritySource,
    DateTime? lastUpdated,
  }) = _UnifiedContact;

  /// The name shown everywhere. `localAlias` (phonebook) wins over the
  /// directory name when present, so the user's rename is preserved.
  String? get resolvedDisplayName =>
      _nonBlank(localAlias) ?? _nonBlank(canonicalDisplayName);

  /// Never-empty display helper for widgets.
  String get displayNameOrId => resolvedDisplayName ?? matrixId;

  bool get hasResolvedDisplayName => resolvedDisplayName != null;

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
