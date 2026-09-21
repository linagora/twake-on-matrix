import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contacts_providers.g.dart';

// `GetTomContactsInteractor` predates the Riverpod migration and is still
// consumed by the non-Riverpod `ContactsManager`; this provider gives
// Riverpod consumers a `ref.read` path instead of reaching into GetIt.
@riverpod
GetTomContactsInteractor getTomContactsInteractor(Ref ref) =>
    getIt.get<GetTomContactsInteractor>();
