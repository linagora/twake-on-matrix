import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin WellKnownMixin {
  static const twakeChatKey = 'app.twake.chat';
  static const _enableInvitation = 'enable_invitations';
  static const supportContact = 'support_contact';

  final ValueNotifier<DiscoveryInformation?> discoveryInformationNotifier =
      ValueNotifier(null);

  Future<void> getWellKnownInformation(Client client) async {
    try {
      final result = await client.getWellknown();
      Logs().d('WellKnownMixin::getWellKnownInformation() well-known $result');
      discoveryInformationNotifier.value = result;
    } catch (e) {
      discoveryInformationNotifier.value = null;
      Logs().e(
        'WellKnownMixin::getWellKnownInformation() Error checking wellknown status: $e',
      );
    }
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
