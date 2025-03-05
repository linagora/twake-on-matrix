import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_address_book_state.dart';
import 'package:fluffychat/domain/repository/contact/address_book_repository.dart';
import 'package:matrix/matrix.dart';

class GetAddressBookInteractor {
  final AddressBookRepository _addressBookRepository =
      getIt.get<AddressBookRepository>();

  Stream<Either<Failure, Success>> execute() async* {
    try {
      final response = await _addressBookRepository.getAddressBook();
      if (response.addressBooks?.isEmpty == true) {
        yield const Left(GetAddressBookIsEmptyState());
      } else {
        yield Right(
          GetAddressBookSuccessState(addressBooks: response.addressBooks!),
        );
      }
    } catch (e) {
      Logs().e('GetAddressBookInteractor::execute', e);
      yield Left(GetAddressBookFailureState(exception: e));
    }
  }
}
