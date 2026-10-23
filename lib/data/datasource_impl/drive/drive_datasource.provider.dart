import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/drive/drive_bridge_datasource.dart';
import 'package:twake_chat/data/datasource/drive/drive_token_datasource.dart';
import 'package:twake_chat/data/datasource_impl/drive/drive_bridge_datasource_impl.dart';
import 'package:twake_chat/data/datasource_impl/drive/drive_token_datasource_impl.dart';
import 'package:twake_chat/data/network/drive/drive_api.provider.dart';

part 'drive_datasource.provider.g.dart';

@riverpod
DriveBridgeDatasource driveBridgeDatasource(Ref ref) =>
    DriveBridgeDatasourceImpl(ref.watch(driveBridgeApiProvider));

@riverpod
DriveTokenDatasource driveTokenDatasource(Ref ref) =>
    DriveTokenDatasourceImpl(ref.watch(driveApiProvider));
