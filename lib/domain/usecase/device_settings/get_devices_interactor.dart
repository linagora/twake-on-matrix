import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/device_settings/get_devices_state.dart';
import 'package:matrix/matrix.dart';

class GetDevicesInteractor {
  Stream<Either<Failure, Success>> execute({required Client client}) async* {
    yield const Right(GetDevicesLoading());

    try {
      final devices = await client.getDevices();
      if (devices == null || devices.isEmpty) {
        yield Left(GetDevicesEmpty());
        return;
      }
      yield Right(GetDevicesSuccess(devices: devices));
    } catch (e) {
      Logs().e('GetDevicesInteractor::execute', e);
      yield Left(GetDevicesFailed(exception: e));
    }
  }
}
