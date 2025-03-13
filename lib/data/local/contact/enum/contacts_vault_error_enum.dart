enum ContactsVaultErrorEnum {
  uploadError,
  responseIsNull;

  String get message {
    switch (this) {
      case ContactsVaultErrorEnum.uploadError:
        return 'Error uploading contacts vault';
      case ContactsVaultErrorEnum.responseIsNull:
        return 'Response is null';
    }
  }
}
