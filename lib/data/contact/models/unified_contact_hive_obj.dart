import 'package:json_annotation/json_annotation.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

part 'unified_contact_hive_obj.g.dart';

/// Hive (JSON) representation of a [ContactSourceValue].
@JsonSerializable(explicitToJson: true)
class ContactSourceValueHiveObj {
  const ContactSourceValueHiveObj({
    required this.kind,
    this.displayName,
    this.avatarUrl,
    this.emails = const <String>[],
    this.phones = const <String>[],
    this.active = false,
    this.updatedAt,
  });

  factory ContactSourceValueHiveObj.fromJson(Map<String, dynamic> json) =>
      _$ContactSourceValueHiveObjFromJson(json);

  final String kind;
  final String? displayName;
  final String? avatarUrl;
  final List<String> emails;
  final List<String> phones;
  final bool active;

  /// Milliseconds since epoch (Hive-friendly primitive).
  final int? updatedAt;

  Map<String, dynamic> toJson() => _$ContactSourceValueHiveObjToJson(this);
}

/// Hive (JSON) representation of a [UnifiedContact].
@JsonSerializable(explicitToJson: true)
class UnifiedContactHiveObj {
  const UnifiedContactHiveObj({
    required this.matrixId,
    this.canonicalDisplayName,
    this.localAlias,
    this.avatarUrl,
    this.emails = const <String>[],
    this.phones = const <String>[],
    this.active = false,
    this.sources = const <ContactSourceValueHiveObj>[],
    this.prioritySource,
    this.lastUpdated,
  });

  factory UnifiedContactHiveObj.fromJson(Map<String, dynamic> json) =>
      _$UnifiedContactHiveObjFromJson(json);

  final String matrixId;
  final String? canonicalDisplayName;
  final String? localAlias;
  final String? avatarUrl;
  final List<String> emails;
  final List<String> phones;
  final bool active;
  final List<ContactSourceValueHiveObj> sources;
  final String? prioritySource;
  final int? lastUpdated;

  Map<String, dynamic> toJson() => _$UnifiedContactHiveObjToJson(this);
}

ContactSourceKind? _kindOrNull(String? name) =>
    name == null ? null : ContactSourceKind.values.asNameMap()[name];

extension ContactSourceValueHiveObjMapper on ContactSourceValueHiveObj {
  ContactSourceValue? toEntity() {
    final resolvedKind = _kindOrNull(kind);
    if (resolvedKind == null) return null;
    return ContactSourceValue(
      kind: resolvedKind,
      displayName: displayName,
      avatarUrl: avatarUrl,
      emails: emails,
      phones: phones,
      active: active,
      updatedAt: updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAt!, isUtc: true),
    );
  }
}

extension ContactSourceValueMapper on ContactSourceValue {
  ContactSourceValueHiveObj toHiveObj() => ContactSourceValueHiveObj(
    kind: kind.name,
    displayName: displayName,
    avatarUrl: avatarUrl,
    emails: emails,
    phones: phones,
    active: active,
    updatedAt: updatedAt?.toUtc().millisecondsSinceEpoch,
  );
}

extension UnifiedContactHiveObjMapper on UnifiedContactHiveObj {
  UnifiedContact toEntity() => UnifiedContact(
    matrixId: matrixId,
    canonicalDisplayName: canonicalDisplayName,
    localAlias: localAlias,
    avatarUrl: avatarUrl,
    emails: emails,
    phones: phones,
    active: active,
    sources: sources
        .map((source) => source.toEntity())
        .whereType<ContactSourceValue>()
        .toList(),
    prioritySource: _kindOrNull(prioritySource),
    lastUpdated: lastUpdated == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastUpdated!, isUtc: true),
  );
}

extension UnifiedContactMapper on UnifiedContact {
  UnifiedContactHiveObj toHiveObj() => UnifiedContactHiveObj(
    matrixId: matrixId,
    canonicalDisplayName: canonicalDisplayName,
    localAlias: localAlias,
    avatarUrl: avatarUrl,
    emails: emails,
    phones: phones,
    active: active,
    sources: sources.map((source) => source.toHiveObj()).toList(),
    prioritySource: prioritySource?.name,
    lastUpdated: lastUpdated?.toUtc().millisecondsSinceEpoch,
  );
}
