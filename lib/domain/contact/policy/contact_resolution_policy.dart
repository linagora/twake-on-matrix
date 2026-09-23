import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

/// Pure domain policy that turns the raw values of several sources into a
/// single [UnifiedContact] (read model keyed by `matrixId`).
///
/// This is the ONLY place in the app that knows the merge / priority rules.
/// It replaces the three previous ad-hoc implementations:
/// - `ContactsViewControllerMixin._combineTomContacts`
/// - `presentation_contact_extension.dart` `combineDuplicateContact`
/// - `search_mixin.dart` `combineDuplicateContactAndChat`
///
/// Default priority (option C of the migration note):
/// - canonical name: TOM UserInfo > TOM AddressBook > Matrix profile >
///   Matrix room member
/// - local alias: device phonebook — when present it becomes
///   [UnifiedContact.resolvedDisplayName] and is shown app-wide
/// - avatar: TOM UserInfo > Matrix profile > TOM AddressBook >
///   Matrix room member > phonebook
class ContactResolutionPolicy {
  const ContactResolutionPolicy({
    this.displayNamePriority = defaultDisplayNamePriority,
    this.avatarPriority = defaultAvatarPriority,
    this.localAliasSource = ContactSourceKind.phonebook,
  });

  static const List<ContactSourceKind> defaultDisplayNamePriority = [
    ContactSourceKind.tomUserInfo,
    ContactSourceKind.tomAddressBook,
    ContactSourceKind.matrixProfile,
    ContactSourceKind.matrixRoomMember,
    ContactSourceKind.manual,
  ];

  static const List<ContactSourceKind> defaultAvatarPriority = [
    ContactSourceKind.tomUserInfo,
    ContactSourceKind.matrixProfile,
    ContactSourceKind.tomAddressBook,
    ContactSourceKind.matrixRoomMember,
    ContactSourceKind.phonebook,
    ContactSourceKind.manual,
  ];

  final List<ContactSourceKind> displayNamePriority;
  final List<ContactSourceKind> avatarPriority;

  /// Source whose [ContactSourceValue.displayName] is treated as the user's
  /// personal alias (wins over the canonical directory name).
  final ContactSourceKind localAliasSource;

  UnifiedContact resolve({
    required String matrixId,
    Iterable<ContactSourceValue> values = const <ContactSourceValue>[],
  }) {
    final byKind = _mergeByKind(values);

    final alias = _pickName(byKind, <ContactSourceKind>[localAliasSource]);
    final canonical = _pickName(byKind, displayNamePriority);

    final resolved = _nonEmpty(alias.value) ?? canonical.value;
    final prioritySource = _nonEmpty(alias.value) != null
        ? alias.kind
        : canonical.kind;

    final avatar = _pickAvatar(byKind);

    return UnifiedContact(
      matrixId: matrixId,
      canonicalDisplayName: canonical.value,
      localAlias: _nonEmpty(alias.value),
      avatarUrl: avatar,
      emails: _unique(byKind.values.expand((value) => value.emails)),
      phones: _unique(byKind.values.expand((value) => value.phones)),
      active: byKind.values.any((value) => value.active),
      sources: byKind.values.toList(growable: false),
      prioritySource: resolved == null ? null : prioritySource,
      lastUpdated: _latest(byKind.values.map((value) => value.updatedAt)),
    );
  }

  /// Merges several snapshots of the same source kind into one, keeping the
  /// first non-empty name / avatar and the union of third-party ids.
  Map<ContactSourceKind, ContactSourceValue> _mergeByKind(
    Iterable<ContactSourceValue> values,
  ) {
    final result = <ContactSourceKind, ContactSourceValue>{};
    for (final value in values) {
      final existing = result[value.kind];
      if (existing == null) {
        result[value.kind] = value;
        continue;
      }
      result[value.kind] = ContactSourceValue(
        kind: value.kind,
        displayName:
            _nonEmpty(existing.displayName) ?? _nonEmpty(value.displayName),
        avatarUrl: _nonEmpty(existing.avatarUrl) ?? _nonEmpty(value.avatarUrl),
        emails: _unique([...existing.emails, ...value.emails]),
        phones: _unique([...existing.phones, ...value.phones]),
        active: existing.active || value.active,
        updatedAt: _latest([existing.updatedAt, value.updatedAt]),
      );
    }
    return result;
  }

  ({String? value, ContactSourceKind? kind}) _pickName(
    Map<ContactSourceKind, ContactSourceValue> byKind,
    List<ContactSourceKind> priority,
  ) {
    for (final kind in priority) {
      final name = _nonEmpty(byKind[kind]?.displayName);
      if (name != null) {
        return (value: name, kind: kind);
      }
    }
    return (value: null, kind: null);
  }

  String? _pickAvatar(Map<ContactSourceKind, ContactSourceValue> byKind) {
    for (final kind in avatarPriority) {
      final avatar = _nonEmpty(byKind[kind]?.avatarUrl);
      if (avatar != null) {
        return avatar;
      }
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  static DateTime? _latest(Iterable<DateTime?> dates) {
    DateTime? latest;
    for (final date in dates) {
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }
    return latest;
  }
}
