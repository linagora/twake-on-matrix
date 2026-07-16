import 'dart:async';

import 'package:fluffychat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_state.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_device_verification_banner_view_model.g.dart';

@riverpod
class ChatDeviceVerificationBannerViewModel
    extends _$ChatDeviceVerificationBannerViewModel {
  StreamSubscription<SyncUpdate>? _onSyncSubscription;
  bool _dismissed = false;

  @override
  DevicesBannerState build(Room room) {
    // Device keys can still be loading (or change later, e.g. after
    // completing verification elsewhere), so re-evaluate on every sync
    // rather than only once at build time.
    _onSyncSubscription = client.onSync.stream.listen((_) => _refresh());
    ref.onDispose(() => _onSyncSubscription?.cancel());
    return _computeState();
  }

  Client get client => room.client;

  void _refresh() => state = _computeState();

  DevicesBannerState _computeState() {
    if (_dismissed) return DevicesBannerInitialState();
    return _isCurrentSessionUnverified()
        ? const DisplayWarningBannerState()
        : DevicesBannerInitialState();
  }

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
    _dismissed = true;
    state = DevicesBannerInitialState();
  }
}
