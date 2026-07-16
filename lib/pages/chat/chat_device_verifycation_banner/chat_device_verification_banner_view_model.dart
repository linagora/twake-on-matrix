import 'package:fluffychat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_state.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_device_verification_banner_view_model.g.dart';

@riverpod
class ChatDeviceVerificationBannerViewModel
    extends _$ChatDeviceVerificationBannerViewModel {
  @override
  DevicesBannerState build(Room room) {
    return _isCurrentSessionUnverified()
        ? const DisplayWarningBannerState()
        : DevicesBannerInitialState();
  }

  Client get client => room.client;

  bool _isCurrentSessionUnverified() {
    final deviceId = client.deviceID;
    if (deviceId == null) return false;
    final deviceKeys = client.userDeviceKeys[client.userID]?.deviceKeys;
    // encryptToDevice reflects whether this device will actually receive
    // room keys and be able to decrypt messages (per ShareKeysWith policy),
    // unlike directVerified/verified which the SDK force-trusts for the
    // own device regardless of any user action.
    return deviceKeys?[deviceId]?.encryptToDevice == false;
  }

  void onDismissBanner() {
    state = DevicesBannerInitialState();
  }
}
