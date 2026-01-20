import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:matrix/matrix.dart' hide Contact;

class GetCombinedContactsInteractor {
  final GetTomContactsInteractor getTomContactsInteractor;
  final LookupMatchContactInteractor lookupMatchContactInteractor;

  GetCombinedContactsInteractor({
    required this.getTomContactsInteractor,
    required this.lookupMatchContactInteractor,
  });

  Stream<Either<Failure, Success>> execute() async* {
    yield const Right(ContactsLoading());

    // Execute both interactors concurrently
    final tomContactsFuture = getTomContactsInteractor.execute().last;
    final lookupContactsFuture = lookupMatchContactInteractor.execute().last;

    final results =
        await Future.wait([tomContactsFuture, lookupContactsFuture]);

    final tomResult = results[0];
    final lookupResult = results[1];

    // Track results separately
    List<Contact> tomContacts = [];
    List<Contact> lookupContacts = [];
    Failure? tomFailure;
    Failure? lookupFailure;

    // Process Tom Contacts (Address Book)
    tomResult.fold(
      (failure) {
        if (failure is! GetContactsIsEmpty) {
          tomFailure = failure; // Track actual failures, not empty states
        }
      },
      (success) {
        if (success is GetContactsSuccess) {
          tomContacts = success.contacts;
        }
      },
    );

    // Process Lookup Contacts (Remote Search)
    lookupResult.fold(
      (failure) {
        if (failure is! LookupContactsEmpty) {
          lookupFailure = failure; // Track actual failures
        }
      },
      (success) {
        if (success is LookupMatchContactSuccess) {
          lookupContacts = success.contacts;
        }
      },
    );

    // Decision Logic: Handle different scenarios
    final hasAnyContacts = tomContacts.isNotEmpty || lookupContacts.isNotEmpty;

    if (!hasAnyContacts) {
      // Scenario 1: No contacts from either source
      if (tomFailure != null) {
        yield Left(tomFailure!);
      } else {
        // Swallow lookup failure when Tom is empty
        yield const Left(GetContactsIsEmpty());
      }
    } else {
      // Scenario 2: We have contacts from at least one source

      // Combine and deduplicate contacts
      final combinedContacts =
          _deduplicateContacts(tomContacts, lookupContacts);

      // Yield success with combined contacts
      yield Right(GetContactsSuccess(contacts: combinedContacts));

      // Optional: Log warnings if one source failed but we still have data
      if (tomFailure != null) {
        Logs().e(
          "GetCombinedContactsInteractor::execute: Tom failure $tomFailure",
        );
      }
      if (lookupFailure != null) {
        Logs().e(
          "GetCombinedContactsInteractor::execute: lookupFailure $lookupFailure",
        );
      }
    }
  }

// Helper method to deduplicate
  List<Contact> _deduplicateContacts(
    List<Contact> tomContacts,
    List<Contact> lookupContacts,
  ) {
    final contactMap = <String, Contact>{};

    // Add Tom contacts first (they take precedence)
    for (final contact in tomContacts) {
      contactMap[contact.id] = contact;
    }

    // Add lookup contacts (won't overwrite Tom contacts with same ID)
    for (final contact in lookupContacts) {
      contactMap.putIfAbsent(contact.id, () => contact);
    }

    return contactMap.values.toList();
  }
}
