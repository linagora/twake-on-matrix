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
    final enableInvitation = (additionalProperties?[twakeChatKey]
        as Map<String, dynamic>?)?[_enableInvitation] as bool?;
    Logs().d(
      'WellKnownMixin::supportInvitation(): enableInvitation - $enableInvitation',
    );
    return enableInvitation ?? false;
  }
}
