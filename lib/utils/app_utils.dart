import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class AppUtils {
  const AppUtils._();

  static Future<bool> validateHomeServerExisted({
    required String homeServer,
    VoidCallback? onActionCallback,
  }) async {
    try {
      final clients = await ClientManager.getClients();
      Logs().i(
        'AppUtils::validateHomeServerExisted:Clients = ${clients.map((client) => client.homeserver).toString()}',
      );

      final loggedInHomeServers = clients
          .map((client) => client.homeserver?.toString())
          .whereType<String>()
          .toSet();

      Logs().i(
        'AppUtils::validateHomeServerExisted: All HomeServers: $loggedInHomeServers',
      );

      final exists = loggedInHomeServers.any(
        (existingServer) => existingServer.contains(homeServer),
      );

      if (exists && !AppConfig.supportMultipleAccountsInTheSameHomeserver) {
        onActionCallback?.call();
        return true;
      }

      return false;
    } catch (e) {
      Logs().e(
        'AppUtils::validateHomeServerExisted: Exception: $e',
      );
      return false;
    }
  }
}
