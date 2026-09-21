import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';

part 'contacts_providers.g.dart';

// `GetTomContactsInteractor` predates the Riverpod migration and is still
// consumed by the non-Riverpod `ContactsManager`; this provider gives
// Riverpod consumers a `ref.read` path instead of reaching into GetIt.
@riverpod
GetTomContactsInteractor getTomContactsInteractor(Ref ref) =>
    getIt.get<GetTomContactsInteractor>();

/// Pure DI: the resolution policy has no dependency and no state.
///
/// It is exposed as a provider from the start so that call sites added in the
/// later PRs (store, service, controller) never instantiate it directly.
@riverpod
ContactResolutionPolicy contactResolutionPolicy(Ref ref) =>
    const ContactResolutionPolicy();
