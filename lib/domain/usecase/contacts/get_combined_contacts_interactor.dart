import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';

class GetCombinedContactsInteractor {
  final GetTomContactsInteractor getTomContactsInteractor;
  final LookupMatchContactInteractor lookupMatchContactInteractor;

  GetCombinedContactsInteractor({
    required this.getTomContactsInteractor,
    required this.lookupMatchContactInteractor,
  });

  Stream<Either<Failure, Success>> execute() async* {
    yield const Right(ContactsLoading());

    // Execute both interactors concurrentlyz
    final tomContactsFuture = getTomContactsInteractor.execute().last;
    final lookupContactsFuture = lookupMatchContactInteractor.execute().last;

    final results =
        await Future.wait([tomContactsFuture, lookupContactsFuture]);

    final tomResult = results[0];
    final lookupResult = results[1];

    List<Contact> tomContacts = [];
    List<Contact> lookupContacts = [];
    Failure? failureState;

    // Process Tom Contacts (Address Book)
    tomResult.fold(
      (failure) {
        if (failure is! GetContactsIsEmpty) {
          failureState = failure; // Keep track of error
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
        // If lookup fails, similar logic.
        if (failure is! LookupContactsEmpty) {
          // If we already had a failure from Tom, keep it or overwrite?
          // If Tom succeeded, we probably ignore this failure or show a warning?
          // For this implementation, let's treat it as empty list but maybe yield Failure if both fail.
          if (failureState != null) failureState = failure;
        }
      },
      (success) {
        if (success is LookupMatchContactSuccess) {
          lookupContacts = success.contacts;
        }
      },
    );

    // If both failed with actual errors (not just empty), return failure
    if (tomContacts.isEmpty && lookupContacts.isEmpty && failureState != null) {
      yield Left(failureState!);
      return;
    }

    // Combine and Deduplicate
    // Priority to Tom Contacts
    // We use a Map keyed by ID to ensure uniqueness, initializing with Tom Contacts
    final Map<String, Contact> combinedMap = {};

    for (final contact in tomContacts) {
      combinedMap[contact.id] = contact;
    }

    for (final contact in lookupContacts) {
      // If id is not already present, add it.
      // We also might need to check other properties if ID isn't consistent across sources,
      // but assuming ID is the matrix ID or valid unique ID.
      if (!combinedMap.containsKey(contact.id)) {
        combinedMap[contact.id] = contact;
      }
    }

    final combinedList = combinedMap.values.toList();

    if (combinedList.isEmpty) {
      yield const Left(GetContactsIsEmpty());
    } else {
      yield Right(GetContactsSuccess(contacts: combinedList));
    }
  }
}
