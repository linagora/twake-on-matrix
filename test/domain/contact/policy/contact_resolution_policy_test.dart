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

    test('phonebook alias becomes the resolved display name and priority', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
          value(ContactSourceKind.phonebook, name: 'Jean Travail'),
        ],
      );

      expect(contact.resolvedDisplayName, 'Jean Travail');
      expect(contact.prioritySource, ContactSourceKind.phonebook);
    });

    test('directory source wins the priority when no alias exists', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
          value(ContactSourceKind.matrixProfile, name: 'Jean Matrix'),
        ],
      );

      expect(contact.canonicalDisplayName, 'Jean Dupont');
      expect(contact.prioritySource, ContactSourceKind.tomUserInfo);
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

    test('returns an empty projection for an empty source list', () {
      final contact = policy.resolve(matrixId: matrixId);

      expect(contact.resolvedDisplayName, isNull);
      expect(contact.lastUpdated, isNull);
    });

    test('empty source list yields empty collections', () {
      final contact = policy.resolve(matrixId: matrixId);

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
}
