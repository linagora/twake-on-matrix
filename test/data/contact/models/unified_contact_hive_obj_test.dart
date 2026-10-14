import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/models/unified_contact_hive_obj.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

void main() {
  test('UnifiedContact survives a Hive (JSON) round-trip', () {
    final contact = UnifiedContact(
      matrixId: '@jean:matrix.company.com',
      canonicalDisplayName: 'Jean Dupont',
      localAlias: 'Jean Travail',
      avatarUrl: 'mxc://company/avatar',
      emails: ['jean@company.com'],
      phones: ['+33123456789'],
      prioritySource: ContactSourceKind.phonebook,
      lastUpdated: DateTime.utc(2026, 6, 1, 12, 30),
      sources: [
        const ContactSourceValue(
          kind: ContactSourceKind.tomUserInfo,
          displayName: 'Jean Dupont',
        ),
        const ContactSourceValue(
          kind: ContactSourceKind.phonebook,
          displayName: 'Jean Travail',
          emails: ['jean@company.com'],
          phones: ['+33123456789'],
        ),
      ],
    );

    final restored = UnifiedContactHiveObj.fromJson(
      contact.toHiveObj().toJson(),
    ).toEntity();

    expect(restored, contact);
    expect(restored.lastUpdated, DateTime.utc(2026, 6, 1, 12, 30));
    expect(restored.prioritySource, ContactSourceKind.phonebook);
    expect(restored.sources, hasLength(2));
  });

  test('empty optional fields survive a round-trip', () {
    const contact = UnifiedContact(matrixId: '@empty:server');

    final restored = UnifiedContactHiveObj.fromJson(
      contact.toHiveObj().toJson(),
    ).toEntity();

    expect(restored, contact);
    expect(restored.resolvedDisplayName, isNull);
  });
}
