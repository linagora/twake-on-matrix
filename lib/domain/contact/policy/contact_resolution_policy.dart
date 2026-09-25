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
  ];

  static const List<ContactSourceKind> defaultAvatarPriority = [
    ContactSourceKind.tomUserInfo,
    ContactSourceKind.matrixProfile,
    ContactSourceKind.tomAddressBook,
    ContactSourceKind.matrixRoomMember,
    ContactSourceKind.phonebook,
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
      sources: byKind.values.toList(growable: false),
      prioritySource: resolved == null ? null : prioritySource,
      lastUpdated: _latest(byKind.values.map((value) => value.updatedAt)),
    );
  }

  /// Merges several snapshots of the same source kind into one, keeping the
  /// newest non-empty name / avatar (by [ContactSourceValue.updatedAt]) and
  /// the union of third-party ids.
  ///
  /// A snapshot without `updatedAt` is treated as the oldest one: a dated
  /// value beats an undated one, and undated ties keep the first occurrence
  /// so the result is stable regardless of the iteration order.
  Map<ContactSourceKind, ContactSourceValue> _mergeByKind(
    Iterable<ContactSourceValue> values,
  ) {
    final byKind = <ContactSourceKind, List<ContactSourceValue>>{};
    for (final value in values) {
      byKind.putIfAbsent(value.kind, () => []).add(value);
    }

    return byKind.map((kind, snapshots) {
      return MapEntry(
        kind,
        ContactSourceValue(
          kind: kind,
          displayName: _newestNonEmpty(snapshots, (value) => value.displayName),
          avatarUrl: _newestNonEmpty(snapshots, (value) => value.avatarUrl),
          emails: _unique(snapshots.expand((value) => value.emails)),
          phones: _unique(snapshots.expand((value) => value.phones)),
          updatedAt: _latest(snapshots.map((value) => value.updatedAt)),
        ),
      );
    });
  }

  /// Non-empty [field] taken from the snapshot with the most recent
  /// `updatedAt`; empty values never win over a real one.
  static String? _newestNonEmpty(
    List<ContactSourceValue> snapshots,
    String? Function(ContactSourceValue) field,
  ) {
    String? best;
    DateTime? bestUpdatedAt;
    for (final snapshot in snapshots) {
      final candidate = _nonEmpty(field(snapshot));
      if (candidate == null) continue;
      if (best == null || _isNewer(snapshot.updatedAt, bestUpdatedAt)) {
        best = candidate;
        bestUpdatedAt = snapshot.updatedAt;
      }
    }
    return best;
  }

  /// `true` when [candidate] is known to be more recent than [current].
  /// A missing timestamp counts as the oldest possible one.
  static bool _isNewer(DateTime? candidate, DateTime? current) {
    if (candidate == null) return false;
    if (current == null) return true;
    return candidate.isAfter(current);
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
