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
    test('phonebook alias wins over the directory name everywhere', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
          value(ContactSourceKind.phonebook, name: 'Jean Travail'),
          value(ContactSourceKind.matrixProfile, name: 'Jean Dupont'),
        ],
      );

      expect(contact.canonicalDisplayName, 'Jean Dupont');
      expect(contact.localAlias, 'Jean Travail');
      expect(contact.resolvedDisplayName, 'Jean Travail');
      expect(contact.prioritySource, ContactSourceKind.phonebook);
    });

    test('falls back to the directory when there is no phonebook alias', () {
      final contact = policy.resolve(
        matrixId: matrixId,
        values: [
          value(ContactSourceKind.tomUserInfo, name: 'Jean Dupont'),
          value(ContactSourceKind.matrixProfile, name: 'Jean Matrix'),
        ],
      );

      expect(contact.canonicalDisplayName, 'Jean Dupont');
      expect(contact.localAlias, isNull);
      expect(contact.resolvedDisplayName, 'Jean Dupont');
      expect(contact.prioritySource, ContactSourceKind.tomUserInfo);
    });

    test(
      'falls back to the Matrix profile when no directory source exists',
      () {
        final contact = policy.resolve(
          matrixId: matrixId,
          values: [
            value(ContactSourceKind.matrixRoomMember, name: 'Room name'),
            value(ContactSourceKind.matrixProfile, name: 'Matrix name'),
          ],
        );

        expect(contact.resolvedDisplayName, 'Matrix name');
        expect(contact.prioritySource, ContactSourceKind.matrixProfile);
      },
    );

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
      expect(contact.displayNameOrId, matrixId);
      expect(contact.hasResolvedDisplayName, isFalse);
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
      expect(contact.emails, isEmpty);
      expect(contact.phones, isEmpty);
      expect(contact.sources, isEmpty);
      expect(contact.lastUpdated, isNull);
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
