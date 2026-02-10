class TwakeEventMessages {
  static Map<String, Map<String, Map<String, dynamic>>>
  updateAddressBookMessage(String clientId, String senderDeviceId) {
    return {
      clientId: {
        '*': {
          'action': 'update_address_book',
          'sender_device_id': senderDeviceId,
        },
      },
    };
  }
}
