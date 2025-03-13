enum ContactsHiveErrorEnum {
  storeError;

  String get message {
    switch (this) {
      case ContactsHiveErrorEnum.storeError:
        return 'Error storing contacts';
    }
  }
}
