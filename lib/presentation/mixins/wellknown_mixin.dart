import 'dart:convert';

import 'package:fluffychat/utils/custom_http_client.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

mixin WellKnownMixin {
  static const twakeChatKey = 'app.twake.chat';
  static const _enableInvitation = 'enable_invitations';
  static const supportContact = 'support_contact';

  final ValueNotifier<DiscoveryInformation?> discoveryInformationNotifier =
      ValueNotifier(null);

  Future<void> getWellKnownInformation(Client client) async {
    final homeserver = client.homeserver;
    if (homeserver == null) {
      return;
    }
    final result = await discoverFromHomeserver(homeserver);
    if (result == null) return;
    Logs().d('WellKnownMixin::getWellKnownInformation() well-known $result');
    discoveryInformationNotifier.value = result;
  }

  static Future<DiscoveryInformation?> discoverFromHomeserver(
    Uri homeserver, {
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? _createHttpClient();
    try {
      final response = await client.get(
        Uri.https(homeserver.authority, '/.well-known/matrix/client'),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Well-known request failed with status ${response.statusCode}',
        );
      }
      final discoveryJson = jsonDecode(utf8.decode(response.bodyBytes));
      if (discoveryJson is! Map) {
        throw const FormatException('Well-known response is not a JSON object');
      }
      return DiscoveryInformation.fromJson(
        Map<String, Object?>.from(discoveryJson),
      );
    } catch (e, s) {
      Logs().e(
        'WellKnownMixin::discoverFromHomeserver() Error checking wellknown '
        'status (keeping previous value): $e',
        e,
        s,
      );
      return null;
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  static http.Client _createHttpClient() => PlatformInfos.isAndroid
      ? CustomHttpClient.createHTTPClient()
      : http.Client();

  bool supportInvitation() {
    final additionalProperties =
        discoveryInformationNotifier.value?.additionalProperties;
    final twakeChatData = additionalProperties?[twakeChatKey];
    final enableInvitation = twakeChatData is Map<String, dynamic>
        ? twakeChatData[_enableInvitation] as bool?
        : null;
    Logs().d(
      'WellKnownMixin::supportInvitation(): enableInvitation - $enableInvitation',
    );
    return enableInvitation ?? false;
  }
}
