import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/app_state/contact/get_contacts_state.dart';
import 'package:twake_chat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:twake_chat/domain/repository/contact/address_book_repository.dart';

class GetTomContactsInteractor {
  final AddressBookRepository addressBookRepository = getIt
      .get<AddressBookRepository>();

  GetTomContactsInteractor();

  /// Whether a ToM server has been configured for the active session. On a
  /// non-Twake homeserver (or before the configuration is restored) the ToM
  /// URL interceptor has no base URL, so requesting `/_twake/addressbook`
  /// would fail with "No host specified in URI".
  bool get _isToMServerConfigured {
    final tomServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.tomServerUrlInterceptorName,
    );
    return tomServerUrlInterceptor.baseUrl != null;
  }

  Stream<Either<Failure, Success>> execute() async* {
    if (!_isToMServerConfigured) {
      yield const Left(GetContactsIsEmpty());
      return;
    }
    try {
      yield const Right(ContactsLoading());
      final response = await addressBookRepository.getAddressBook();

      final contacts = response.addressBooks?.toContacts() ?? [];

      if (contacts.isEmpty) {
        yield const Left(GetContactsIsEmpty());
      } else {
        yield Right(GetContactsSuccess(contacts: contacts));
      }
    } catch (e) {
      yield Left(GetContactsFailure(keyword: '', exception: e));
    }
  }
}
