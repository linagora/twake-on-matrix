import 'package:fluffychat/di/global/configuration/tom_configuration_di.dart';
import 'package:fluffychat/di/global/hive_di.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/di/presentation/recovery_words_di.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class GetItInitializer {
  static final GetItInitializer _singleton = GetItInitializer._internal();

  factory GetItInitializer() {
    return _singleton;
  }

  GetItInitializer._internal();

  void setUp() {
    NetworkDI().bind();
    HiveDI().bind();
    ToMConfigurationDI().bind();
    RecoveryWordsDI().bind();
  }
}