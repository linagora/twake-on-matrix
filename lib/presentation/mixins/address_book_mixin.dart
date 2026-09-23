import 'package:matrix/matrix.dart';

/// Address book helpers for screens that add contacts.
///
/// Cross-device address book propagation used to be driven by
/// `ContactsManager.postAddressBookNotifier`; it now belongs to the unified
/// contact sync pipeline, so there is nothing to listen to here.
mixin AddressBooksMixin {
  void listenAddressBookEvents(Client client) {
    Logs().d('$runtimeType::listenAddressBookEvents');
  }
}
