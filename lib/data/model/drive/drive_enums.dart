import 'package:json_annotation/json_annotation.dart';

enum DriveDataType {
  @JsonValue('io.cozy.intents')
  intents,
}

enum DriveIntentAction {
  @JsonValue('PICK')
  pick,
}

enum DriveDocType {
  @JsonValue('io.cozy.files')
  files,
}

enum DriveIntentPermission {
  @JsonValue('GET')
  get,
}

enum DriveThemeType { light, dark }

enum DriveExchangeType {
  @JsonValue('app')
  app,
}
