import 'package:collection/collection.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/device_settings/get_devices_state.dart';
import 'package:fluffychat/domain/usecase/device_settings/get_devices_interactor.dart';
import 'package:fluffychat/pages/chat/chat_device_verifycation_banner/chat_device_verification_banner_state.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_device_verification_banner_view_model.g.dart';

@riverpod
class ChatDeviceVerificationBannerViewModel
    extends _$ChatDeviceVerificationBannerViewModel {
  @override
  DevicesBannerState build(Room room) {
    Future.microtask(getDevices);
    return DevicesBannerInitialState();
  }

  final GetDevicesInteractor _getDevicesInteractor = getIt
      .get<GetDevicesInteractor>();

  bool _isOwnDevice(Device userDevice) =>
      userDevice.deviceId == client.deviceID;

  Client get client => room.client;

  Future<void> getDevices() async {
    _getDevicesInteractor
        .execute(client: client)
        .listen(
          (either) => either.fold((failure) {}, (success) {
            if (success is GetDevicesSuccess) {
              final myDevice = success.devices.firstWhereOrNull(_isOwnDevice);
              final myDeviceKeys = client
                  .userDeviceKeys[client.userID]
                  ?.deviceKeys[myDevice?.deviceId];
              if (myDevice != null && myDeviceKeys?.verified == false) {
                state = DisplayWarningBannerState(myDevice: myDevice);
              }
            }
          }),
        );
  }
}
