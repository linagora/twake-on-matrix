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

  Client get client => room.client;

  Future<void> getDevices() async {
    _getDevicesInteractor
        .execute(client: client)
        .listen(
          (either) => either.fold((failure) {}, (success) {
            if (success is GetDevicesSuccess) {
              final deviceKeys = client.userDeviceKeys[client.userID]
                  ?.deviceKeys;
              // encryptToDevice reflects whether this device will actually
              // receive room keys and be able to decrypt messages (per
              // ShareKeysWith policy), unlike directVerified/verified which
              // the SDK force-trusts for the own device regardless of any
              // user action.
              final unverifiedDevices = success.devices
                  .where(
                    (device) =>
                        deviceKeys?[device.deviceId]?.encryptToDevice ==
                        false,
                  )
                  .toList();
              if (unverifiedDevices.isNotEmpty) {
                state = DisplayWarningBannerState(
                  unverifiedDevices: unverifiedDevices,
                );
              }
            }
          }),
        );
  }

  void onDismissBanner() {
    state = DevicesBannerInitialState();
  }
}
