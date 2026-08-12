import 'package:twake_chat/utils/matrix_sdk_extensions/client_well_known_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin WellKnownMixin {
  static const twakeChatKey = 'app.twake.chat';
  static const _enableInvitation = 'enable_invitations';
  static const supportContact = 'support_contact';

  final ValueNotifier<DiscoveryInformation?> discoveryInformationNotifier =
      ValueNotifier(null);

  Future<void> getWellKnownInformation(Client client) async {
    final result = await client.getWellKnownOrFallback(
      fallback: discoveryInformationNotifier.value,
    );
    if (result == null) return;
    Logs().d('WellKnownMixin::getWellKnownInformation() well-known $result');
    discoveryInformationNotifier.value = result;
  }

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
