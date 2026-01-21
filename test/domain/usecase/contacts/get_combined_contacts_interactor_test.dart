import 'package:dartz/dartz.dart';

import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/usecase/contacts/get_combined_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_combined_contacts_interactor_test.mocks.dart';

@GenerateMocks([
  GetTomContactsInteractor,
  LookupMatchContactInteractor,
])
void main() {
  late GetCombinedContactsInteractor interactor;
  late MockGetTomContactsInteractor mockGetTomContactsInteractor;
  late MockLookupMatchContactInteractor mockLookupMatchContactInteractor;

  setUp(() {
    mockGetTomContactsInteractor = MockGetTomContactsInteractor();
    mockLookupMatchContactInteractor = MockLookupMatchContactInteractor();
    interactor = GetCombinedContactsInteractor(
      getTomContactsInteractor: mockGetTomContactsInteractor,
      lookupMatchContactInteractor: mockLookupMatchContactInteractor,
    );
  });

  final contact1 = Contact(
    id: '@user1:example.com',
    displayName: 'User One',
    emails: {Email(address: 'user1@example.com')},
    phoneNumbers: {PhoneNumber(number: '1234567890')},
  );

  final contact2 = Contact(
    id: '@user2:example.com',
    displayName: 'User Two',
    emails: {Email(address: 'user2@example.com')},
    phoneNumbers: {PhoneNumber(number: '9876543210')},
  );

  final contact3 = Contact(
    id: '@user3:example.com',
    displayName: 'User Three',
    emails: {Email(address: 'user3@example.com')},
    phoneNumbers: {PhoneNumber(number: '5555555555')},
  );

  group('GetCombinedContactsInteractor', () {
    test('should return combined contacts from both sources', () async {
      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.value(Right(GetContactsSuccess(contacts: [contact1]))),
      );
      when(mockLookupMatchContactInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Right(LookupMatchContactSuccess(contacts: [contact2])),
        ),
      );

      await expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          Right(GetContactsSuccess(contacts: [contact1, contact2])),
        ]),
      );
    });

    test('should deduplicate preferring Tom contacts', () {
      final duplicateContact =
          contact2.copyWith(displayName: 'User Two from Tom');

      // Tom returns contact1 and duplicateContact
      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Right(
            GetContactsSuccess(contacts: [contact1, duplicateContact]),
          ),
        ),
      );

      // Lookup returns contact2 (same ID as duplicateContact) and contact3
      when(mockLookupMatchContactInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Right(
            LookupMatchContactSuccess(contacts: [contact2, contact3]),
          ),
        ),
      );

      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          // Should contain contact1, duplicateContact (from Tom), and contact3. contact2 is ignored.
          Right(
            GetContactsSuccess(
              contacts: [contact1, duplicateContact, contact3],
            ),
          ),
        ]),
      );
    });

    test('should return all contacts (no filtering by ID)', () {
      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Right(GetContactsSuccess(contacts: [contact1, contact2])),
        ),
      );
      when(mockLookupMatchContactInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          const Right(LookupMatchContactSuccess(contacts: [])),
        ),
      );

      // No filtering happens, so both contacts are returned
      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          Right(GetContactsSuccess(contacts: [contact1, contact2])),
        ]),
      );
    });

    test('should return Tom contacts if Lookup fails', () {
      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Right(GetContactsSuccess(contacts: [contact1])),
        ),
      );
      when(mockLookupMatchContactInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Left(
            LookupContactsFailure(
              keyword: 'val',
              exception: Exception(),
            ),
          ),
        ),
      );

      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          Right(GetContactsSuccess(contacts: [contact1])),
        ]),
      );
    });

    test('should return Lookup contacts if Tom fails (not empty)', () {
      final testException = Exception('test error');
      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Left(
            GetContactsFailure(
              keyword: '',
              exception: testException,
            ),
          ),
        ),
      );
      when(mockLookupMatchContactInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Right(LookupMatchContactSuccess(contacts: [contact2])),
        ),
      );

      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          Right(GetContactsSuccess(contacts: [contact2])),
        ]),
      );
    });

    test('should return empty/failure if both fail/empty', () {
      when(mockGetTomContactsInteractor.execute())
          .thenAnswer((_) => Stream.value(const Left(GetContactsIsEmpty())));
      when(mockLookupMatchContactInteractor.execute())
          .thenAnswer((_) => Stream.value(const Right(LookupContactsEmpty())));

      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );
    });

    test('should return Tom failure if Tom fails and Lookup is empty', () {
      final testException = Exception('test error');
      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Left(
            GetContactsFailure(
              keyword: 'fail',
              exception: testException,
            ),
          ),
        ),
      );
      when(mockLookupMatchContactInteractor.execute())
          .thenAnswer((_) => Stream.value(const Right(LookupContactsEmpty())));

      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          Left(
            GetContactsFailure(
              keyword: 'fail',
              exception: testException,
            ),
          ),
        ]),
      );
    });

    test('should return Empty if Tom is empty even if Lookup fails (swallowed)',
        () {
      when(mockGetTomContactsInteractor.execute())
          .thenAnswer((_) => Stream.value(const Left(GetContactsIsEmpty())));
      when(mockLookupMatchContactInteractor.execute()).thenAnswer(
        (_) => Stream.value(
          Left(
            LookupContactsFailure(
              keyword: 'fail',
              exception: Exception(),
            ),
          ),
        ),
      );

      expectLater(
        interactor.execute(),
        emitsInOrder([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );
    });
  });
}
