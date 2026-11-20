import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(useDataProtectionKeyChain: false),
);
