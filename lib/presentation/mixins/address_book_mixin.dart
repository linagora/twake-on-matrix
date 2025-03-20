import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/post_address_book_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/event/twake_event_messages.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:matrix/matrix.dart';

mixin AddressBooksMixin {
  void listenAddressBookEvents(Client client) {
    final contactsManager = getIt.get<ContactsManager>();
    contactsManager.postAddressBookNotifier().addListener(() {
      contactsManager.postAddressBookNotifier().value.map(
            (newSuccess) => _handleAddressBookUpdatedEvent(client, newSuccess),
          );
    });
  }

  void _handleAddressBookUpdatedEvent(Client client, Success successState) {
    final userId = client.userID;
    final deviceId = client.deviceID;
    if (successState is PostAddressBookSuccessState && userId != null && deviceId != null) {
      client.sendToDevice(
        TwakeEventTypes.addressBookUpdatedEventType,
        client.generateUniqueTransactionId(),
        TwakeEventMessages.updateAddressBookMessage(userId, deviceId),
      );
    }
  }
}
