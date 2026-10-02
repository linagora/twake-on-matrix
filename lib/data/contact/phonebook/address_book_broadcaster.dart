import 'package:matrix/matrix.dart';
import 'package:twake_chat/event/twake_event_messages.dart';
import 'package:twake_chat/event/twake_event_types.dart';

/// Tells the other devices of the account that the address book changed, so
/// they refresh their contacts.
class AddressBookBroadcaster {
  const AddressBookBroadcaster(this._client);

  final Client? Function() _client;

  Future<void> notifyOtherDevices() async {
    final client = _client();
    final userId = client?.userID;
    final deviceId = client?.deviceID;
    if (client == null || userId == null || deviceId == null) return;

    await client.sendToDevice(
      TwakeEventTypes.addressBookUpdatedEventType,
      client.generateUniqueTransactionId(),
      TwakeEventMessages.updateAddressBookMessage(userId, deviceId),
    );
  }
}
