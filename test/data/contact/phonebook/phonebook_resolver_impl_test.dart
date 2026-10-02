import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/contact/phonebook/phonebook_resolver_impl.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/data/model/federation_server/federation_server_information.dart';
import 'package:twake_chat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:twake_chat/domain/app_state/contact/post_address_book_state.dart';
import 'package:twake_chat/domain/app_state/contact/try_get_synced_phone_book_contact_state.dart';
import 'package:twake_chat/domain/exception/federation_configuration_not_found.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/usecase/contacts/federation_look_up_phonebook_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/try_get_synced_phone_book_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/twake_look_up_phonebook_contact_interactor.dart';

import 'phonebook_resolver_impl_test.mocks.dart';

typedef _State = Either<Failure, Success>;

@GenerateNiceMocks([
  MockSpec<TryGetSyncedPhoneBookContactInteractor>(),
  MockSpec<FederationLookUpPhonebookContactInteractor>(),
  MockSpec<TwakeLookupPhonebookContactInteractor>(),
  MockSpec<PostAddressBookInteractor>(),
])
void main() {
  const userId = '@me:server';
  late MockTryGetSyncedPhoneBookContactInteractor tryGetSynced;
  late MockFederationLookUpPhonebookContactInteractor federation;
  late MockTwakeLookupPhonebookContactInteractor twake;
  late MockPostAddressBookInteractor post;
  late FederationConfigurations federationConfigurations;
  late bool federationConfigurationsMissing;
  late int partialFailures;
  late int uploads;

  final contacts = [
    Contact(
      id: '1',
      displayName: 'Alice',
      emails: {Email(address: 'alice@mail.com', matrixId: '@alice:server')},
    ),
  ];

  _State syncedAndFresh() => Right(
    GetSyncedPhoneBookContactSuccessState(
      contacts: contacts,
      timeAvailableForSyncVault: false,
    ),
  );

  _State syncedAndDue() => Right(
    GetSyncedPhoneBookContactSuccessState(
      contacts: contacts,
      timeAvailableForSyncVault: true,
    ),
  );

  void stubSynced(_State state) => when(
    tryGetSynced.execute(userId: anyNamed('userId')),
  ).thenAnswer((_) async => state);

  void stubFederation(Stream<_State> states) => when(
    federation.execute(
      lookupChunkSize: anyNamed('lookupChunkSize'),
      argument: anyNamed('argument'),
    ),
  ).thenAnswer((_) => states);

  void stubTwake(Stream<_State> states) => when(
    twake.execute(argument: anyNamed('argument')),
  ).thenAnswer((_) => states);

  void stubPost(_State state) => when(
    post.execute(addressBooks: anyNamed('addressBooks')),
  ).thenAnswer((_) => Stream.value(state));

  PhonebookResolverImpl build({bool uploadsAddressBook = true}) =>
      PhonebookResolverImpl(
        tryGetSynced: tryGetSynced,
        federationLookUp: federation,
        twakeLookUp: twake,
        postAddressBook: post,
        federationConfigurations: (_) async {
          if (federationConfigurationsMissing) {
            throw FederationConfigurationNotFound();
          }
          return federationConfigurations;
        },
        endpoints: PhonebookLookupEndpoints(
          homeServerUrl: () => 'https://home',
          identityServerUrl: () => 'https://identity',
          accessToken: () => 'token',
        ),
        uploadsAddressBook: uploadsAddressBook,
        onPartialFailure: () => partialFailures++,
        onAddressBookUploaded: () async => uploads++,
      );

  setUp(() {
    tryGetSynced = MockTryGetSyncedPhoneBookContactInteractor();
    federation = MockFederationLookUpPhonebookContactInteractor();
    twake = MockTwakeLookupPhonebookContactInteractor();
    post = MockPostAddressBookInteractor();
    federationConfigurationsMissing = false;
    federationConfigurations = FederationConfigurations(
      fedServerInformation: FederationServerInformation(
        baseUrls: [Uri.parse('https://fed')],
      ),
    );
    partialFailures = 0;
    uploads = 0;
    stubPost(const Right(PostAddressBookSuccessState(updatedAddressBooks: [])));
  });

  test('keeps a valid stored resolution without any lookup', () async {
    stubSynced(syncedAndFresh());

    await build().resolve(userId);

    verifyNever(
      federation.execute(
        lookupChunkSize: anyNamed('lookupChunkSize'),
        argument: anyNamed('argument'),
      ),
    );
    verifyNever(twake.execute(argument: anyNamed('argument')));
    expect(uploads, 0);
  });

  test('runs the federation lookup when the vault sync is due', () async {
    stubSynced(syncedAndDue());
    stubFederation(
      Stream.fromIterable([
        const Right(GetPhonebookContactsLoading()),
        Right(GetPhonebookContactsSuccess(progress: 100, contacts: contacts)),
      ]),
    );

    await build().resolve(userId);

    final argument =
        verify(
              federation.execute(
                lookupChunkSize: 10,
                argument: captureAnyNamed('argument'),
              ),
            ).captured.single
            as dynamic;
    expect(argument.withMxId, userId);
    expect(argument.homeServerUrl, 'https://home');
    expect(argument.withAccessToken, 'token');
    expect(argument.federationUrls, ['https://fed']);
    verify(post.execute(addressBooks: anyNamed('addressBooks'))).called(1);
    expect(uploads, 1);
  });

  test('looks up when nothing is stored yet', () async {
    stubSynced(const Left(GetSyncedPhoneBookContactIsEmpty()));
    stubFederation(
      Stream.value(
        Right(GetPhonebookContactsSuccess(progress: 100, contacts: contacts)),
      ),
    );

    await build().resolve(userId);

    expect(uploads, 1);
  });

  test('uses the Twake lookup when no federation server is set', () async {
    stubSynced(syncedAndDue());
    federationConfigurations = FederationConfigurations(
      fedServerInformation: FederationServerInformation(),
    );
    stubTwake(
      Stream.value(
        Right(GetPhonebookContactsSuccess(progress: 100, contacts: contacts)),
      ),
    );

    await build().resolve(userId);

    verifyNever(
      federation.execute(
        lookupChunkSize: anyNamed('lookupChunkSize'),
        argument: anyNamed('argument'),
      ),
    );
    final argument =
        verify(
              twake.execute(argument: captureAnyNamed('argument')),
            ).captured.single
            as dynamic;
    expect(argument.homeServerUrl, 'https://identity');
    expect(uploads, 1);
  });

  test('falls back to the Twake lookup without federation config', () async {
    stubSynced(syncedAndDue());
    federationConfigurationsMissing = true;
    stubTwake(
      Stream.value(
        Right(GetPhonebookContactsSuccess(progress: 100, contacts: contacts)),
      ),
    );

    await build().resolve(userId);

    verify(twake.execute(argument: anyNamed('argument'))).called(1);
    expect(uploads, 1);
  });

  test('a partial failure warns the user and still uploads', () async {
    stubSynced(syncedAndDue());
    stubFederation(
      Stream.value(
        Left(
          LookUpPhonebookContactPartialFailed(
            exception: 'chunk',
            contacts: contacts,
          ),
        ),
      ),
    );

    await build().resolve(userId);

    expect(partialFailures, 1);
    expect(uploads, 1);
  });

  test('does not upload before the lookup is complete', () async {
    stubSynced(syncedAndDue());
    stubFederation(
      Stream.value(
        Right(GetPhonebookContactsSuccess(progress: 50, contacts: contacts)),
      ),
    );

    await build().resolve(userId);

    verifyNever(post.execute(addressBooks: anyNamed('addressBooks')));
  });

  test('does not upload the address book on the web', () async {
    stubSynced(syncedAndDue());
    stubFederation(
      Stream.value(
        Right(GetPhonebookContactsSuccess(progress: 100, contacts: contacts)),
      ),
    );

    await build(uploadsAddressBook: false).resolve(userId);

    verifyNever(post.execute(addressBooks: anyNamed('addressBooks')));
    expect(uploads, 0);
  });

  test('does not tell the other devices when the upload failed', () async {
    stubSynced(syncedAndDue());
    stubFederation(
      Stream.value(
        Right(GetPhonebookContactsSuccess(progress: 100, contacts: contacts)),
      ),
    );
    stubPost(const Left(PostAddressBookFailureState(exception: 'offline')));

    await build().resolve(userId);

    expect(uploads, 0);
  });

  test('concurrent calls share a single lookup', () async {
    stubSynced(syncedAndDue());
    final gate = Completer<void>();
    stubFederation(() async* {
      await gate.future;
      yield Right<Failure, Success>(
        GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
      );
    }());
    final resolver = build();

    final first = resolver.resolve(userId);
    final second = resolver.resolve(userId);
    gate.complete();
    await Future.wait([first, second]);

    verify(
      federation.execute(
        lookupChunkSize: anyNamed('lookupChunkSize'),
        argument: anyNamed('argument'),
      ),
    ).called(1);
  });

  test('cancel drops the results of the lookup in progress', () async {
    stubSynced(syncedAndDue());
    final gate = Completer<void>();
    stubFederation(() async* {
      await gate.future;
      yield Right<Failure, Success>(
        GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
      );
    }());
    final resolver = build();

    final running = resolver.resolve(userId);
    await resolver.cancel();
    gate.complete();
    await running;

    verifyNever(post.execute(addressBooks: anyNamed('addressBooks')));
    expect(uploads, 0);
  });

  test('never throws when the lookup blows up', () async {
    stubSynced(syncedAndDue());
    stubFederation(Stream.error(StateError('boom')));

    await expectLater(build().resolve(userId), completes);
    expect(uploads, 0);
  });

  test('can run again once the previous lookup completed', () async {
    stubSynced(syncedAndDue());
    stubFederation(Stream.value(const Right(GetPhonebookContactsLoading())));
    final resolver = build();

    await resolver.resolve(userId);
    stubFederation(Stream.value(const Right(GetPhonebookContactsLoading())));
    await resolver.resolve(userId);

    verify(
      federation.execute(
        lookupChunkSize: anyNamed('lookupChunkSize'),
        argument: anyNamed('argument'),
      ),
    ).called(2);
  });
}
