import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';

void main() {
  const policy = ContactResolutionPolicy();
  const matrixId = '@jean:matrix.company.com';

  ContactSourceValue value(
    ContactSourceKind kind, {
    String? name,
    String? avatar,
    List<String> emails = const [],
    List<String> phones = const [],
    DateTime? updatedAt,
  }) => ContactSourceValue(
    kind: kind,
    displayName: name,
    avatarUrl: avatar,
    emails: emails,
    phones: phones,
    updatedAt: updatedAt,
  );

  group('ContactResolutionPolicy display name', () {
    test('resolves display name and priority from source values', () {
      final cases = <String, List<ContactSourceValue>>{
        'phonebook alias wins': [
          value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
          value(ContactSourceKind.phonebook, name: 'Jean Travail'),
          value(ContactSourceKind.matrixProfile, name: 'Jean Dupont'),
        ],
        'no alias falls back to directory': [
          value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
          value(ContactSourceKind.matrixProfile, name: 'Jean Matrix'),
        ],
        'matrix profile when no directory': [
          value(ContactSourceKind.matrixRoomMember, name: 'Room name'),
          value(ContactSourceKind.matrixProfile, name: 'Matrix name'),
        ],
      };

      final resolved = cases.map(
        (label, values) =>
            MapEntry(label, policy.resolve(matrixId: matrixId, values: values)),
      );

      expect(resolved['phonebook alias wins']!.localAlias, 'Jean Travail');
      expect(
        resolved['phonebook alias wins']!.canonicalDisplayName,
        'Jean Dupont',
      );
      expect(resolved['no alias falls back to directory']!.localAlias, isNull);
      expect(
        resolved['no alias falls back to directory']!.resolvedDisplayName,
        'Jean Dupont',
      );
      expect(
        resolved['matrix profile when no directory']!.resolvedDisplayName,
        'Matrix name',
      );
      expect(
        resolved['matrix profile when no directory']!.prioritySource,
        ContactSourceKind.matrixProfile,
      );
    });

    test('resolved name and priority follow the policy rules', () {
      final scenarios = [
        (
          label: 'phonebook alias wins',
          values: [
            value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
            value(ContactSourceKind.phonebook, name: 'Jean Travail'),
          ],
          expectedName: 'Jean Travail',
          expectedPriority: ContactSourceKind.phonebook,
        ),
        (
          label: 'directory wins when no alias',
          values: [
            value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
            value(ContactSourceKind.matrixProfile, name: 'Jean Matrix'),
          ],
          expectedName: 'Jean Dupont',
          expectedPriority: ContactSourceKind.tomUserInfo,
        ),
      ];

      for (final s in scenarios) {
        final contact = policy.resolve(matrixId: matrixId, values: s.values);
        expect(contact.resolvedDisplayName, s.expectedName, reason: s.label);
        expect(contact.prioritySource, s.expectedPriority, reason: s.label);
      }
    });

    test('ignores blank display names and trailing spaces', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: '   '),
          value(ContactSourceKind.tomAddressBook, name: ' Jean Addressbook '),
        ],
      );

      expect(contact.resolvedDisplayName, 'Jean Addressbook');
    });

    test('returns no resolved name when every source is empty', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [value(ContactSourceKind.phonebook)],
      );

      expect(contact.resolvedDisplayName, isNull);
      expect(contact.hasResolvedDisplayName, isFalse);
    });

    test('displayNameOrId falls back to matrixId when no name exists', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [value(ContactSourceKind.phonebook)],
      );

      expect(contact.displayNameOrId, matrixId);
      expect(contact.prioritySource, isNull);
    });
  });

  group('ContactResolutionPolicy avatar', () {
    test('prefers TOM UserInfo avatar over Matrix profile', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(
            ContactSourceKind.matrixProfile,
            name: 'Matrix',
            avatar: 'mxc://matrix',
          ),
          value(
            ContactSourceKind.tomUserInfo,
            name: 'Directory',
            avatar: 'mxc://directory',
          ),
        ],
      );

      expect(contact.avatarUrl, 'mxc://directory');
    });

    test('uses phonebook avatar only as a last resort', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(
            ContactSourceKind.phonebook,
            name: 'Alias',
            avatar: 'mxc://phonebook',
          ),
        ],
      );

      expect(contact.avatarUrl, 'mxc://phonebook');
    });
  });

  group('ContactResolutionPolicy aggregation', () {
    test('unions emails and phones across sources without duplicates', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(
            ContactSourceKind.tomAddressBook,
            name: 'Directory',
            emails: ['jean@company.com', 'j.dupont@company.com'],
            phones: ['+33123456789'],
          ),
          value(
            ContactSourceKind.phonebook,
            name: 'Alias',
            emails: ['jean@company.com'],
            phones: ['+33123456789', '+33612345678'],
          ),
        ],
      );

      expect(contact.emails, ['jean@company.com', 'j.dupont@company.com']);
      expect(contact.phones, ['+33123456789', '+33612345678']);
    });

    test('keeps the latest update timestamp', () {
      final older = DateTime.utc(2026, 1, 1);
      final newer = DateTime.utc(2026, 6, 1);

      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: 'A', updatedAt: older),
          value(ContactSourceKind.phonebook, name: 'B', updatedAt: newer),
        ],
      );

      expect(contact.lastUpdated, newer);
    });

    test('merges several snapshots of the same source kind', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(
            ContactSourceKind.matrixRoomMember,
            name: 'Room A',
            emails: ['a@x.com'],
          ),
          value(
            ContactSourceKind.matrixRoomMember,
            name: '',
            emails: ['b@x.com'],
          ),
        ],
      );

      expect(contact.resolvedDisplayName, 'Room A');
      expect(contact.emails, ['a@x.com', 'b@x.com']);
      expect(contact.sources, hasLength(1));
    });

    test(
      'merges same-kind snapshots by keeping the newest non-empty value',
      () {
        final older = DateTime.utc(2026, 1, 1);
        final newer = DateTime.utc(2026, 6, 1);

        final scenarios = [
          (
            label: 'prefers the newest snapshot of the same source kind',
            values: [
              value(
                ContactSourceKind.matrixProfile,
                name: 'Old name',
                avatar: 'mxc://old',
                updatedAt: older,
              ),
              value(
                ContactSourceKind.matrixProfile,
                name: 'New name',
                avatar: 'mxc://new',
                updatedAt: newer,
              ),
            ],
            expectedName: 'New name',
            expectedAvatar: 'mxc://new',
          ),
          (
            label: 'newest snapshot wins regardless of the iteration order',
            values: [
              value(
                ContactSourceKind.matrixProfile,
                name: 'New name',
                avatar: 'mxc://new',
                updatedAt: newer,
              ),
              value(
                ContactSourceKind.matrixProfile,
                name: 'Old name',
                avatar: 'mxc://old',
                updatedAt: older,
              ),
            ],
            expectedName: 'New name',
            expectedAvatar: 'mxc://new',
          ),
          (
            label: 'empty newest snapshot does not erase the previous name',
            values: [
              value(
                ContactSourceKind.matrixProfile,
                name: 'Kept name',
                avatar: 'mxc://kept',
                updatedAt: older,
              ),
              value(
                ContactSourceKind.matrixProfile,
                name: '   ',
                updatedAt: newer,
              ),
            ],
            expectedName: 'Kept name',
            expectedAvatar: 'mxc://kept',
          ),
          (
            label: 'a dated snapshot beats an undated one',
            values: [
              value(ContactSourceKind.matrixProfile, name: 'Undated'),
              value(
                ContactSourceKind.matrixProfile,
                name: 'Dated',
                updatedAt: older,
              ),
            ],
            expectedName: 'Dated',
            expectedAvatar: null,
          ),
          (
            label: 'keeps the first non-empty value when no snapshot is dated',
            values: [
              value(ContactSourceKind.matrixProfile, name: 'First'),
              value(ContactSourceKind.matrixProfile, name: 'Second'),
            ],
            expectedName: 'First',
            expectedAvatar: null,
          ),
        ];

        for (final s in scenarios) {
          final contact = policy.resolve(matrixId: matrixId, values: s.values);
          expect(contact.resolvedDisplayName, s.expectedName, reason: s.label);
          expect(contact.avatarUrl, s.expectedAvatar, reason: s.label);
        }
      },
    );

    test('returns an empty projection for an empty source list', () {
      final contact = policy.resolve(matrixId: matrixId);

      expect(contact.resolvedDisplayName, isNull);
      expect(contact.lastUpdated, isNull);
      expect(contact.emails, isEmpty);
      expect(contact.phones, isEmpty);
      expect(contact.sources, isEmpty);
    });
  });

  group('ContactResolutionPolicy custom priority', () {
    test('honours an inverted priority list', () {
      const canonicalFirst = ContactResolutionPolicy(
        displayNamePriority: [
          ContactSourceKind.matrixProfile,
          ContactSourceKind.tomUserInfo,
        ],
      );

      final contact = canonicalFirst.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: 'Directory'),
          value(ContactSourceKind.matrixProfile, name: 'Matrix'),
        ],
      );

      expect(contact.resolvedDisplayName, 'Matrix');
      expect(contact.prioritySource, ContactSourceKind.matrixProfile);
    });
  });

  group('ContactResolutionPolicy active status', () {
    test('a contact is active when any source value is active', () {
      final contact = const ContactResolutionPolicy().resolve(
        matrixId: matrixId,
        values: const [
          ContactSourceValue(kind: ContactSourceKind.tomAddressBook),
          ContactSourceValue(kind: ContactSourceKind.phonebook, active: true),
        ],
      );

      expect(contact.active, isTrue);
    });

    test('same-kind snapshots keep the active flag', () {
      final contact = const ContactResolutionPolicy().resolve(
        matrixId: matrixId,
        values: const [
          ContactSourceValue(kind: ContactSourceKind.phonebook, active: true),
          ContactSourceValue(kind: ContactSourceKind.phonebook),
        ],
      );

      expect(contact.active, isTrue);
      expect(contact.sources.single.active, isTrue);
    });

    test('a contact with no active value is inactive', () {
      final contact = const ContactResolutionPolicy().resolve(
        matrixId: matrixId,
        values: const [ContactSourceValue(kind: ContactSourceKind.phonebook)],
      );

      expect(contact.active, isFalse);
    });
  });
}
