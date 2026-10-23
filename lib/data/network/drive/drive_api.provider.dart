import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/bridge/cozy_bridge.provider.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/drive/drive_api.dart';
import 'package:twake_chat/data/network/drive/drive_bridge_api.dart';
import 'package:twake_chat/data/network/drive/drive_dio.dart';

part 'drive_api.provider.g.dart';

@Riverpod(keepAlive: true)
DioClient driveDioClient(Ref ref) => DioClient(createDriveDio());

@riverpod
DriveApi driveApi(Ref ref) => DriveApi(ref.watch(driveDioClientProvider));

@riverpod
DriveBridgeApi driveBridgeApi(Ref ref) =>
    DriveBridgeApi(ref.watch(cozyBridgeProvider));
