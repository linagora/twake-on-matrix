import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/device_settings/get_devices_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_settings_providers.g.dart';

@riverpod
GetDevicesInteractor getDevicesInteractor(Ref ref) =>
    getIt.get<GetDevicesInteractor>();
