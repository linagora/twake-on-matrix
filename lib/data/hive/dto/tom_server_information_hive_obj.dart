import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/hive/hive_constants.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:hive/hive.dart';

part 'tom_server_information_hive_obj.g.dart';

@HiveType(typeId: HiveConstants.typeIdTomServerInformation)
class ToMServerInformationHiveObj extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String? baseUrl;

  @HiveField(1)
  final String? serverName;

  ToMServerInformationHiveObj(this.baseUrl, this.serverName);

  @override
  List<Object?> get props => [baseUrl, serverName];

  ToMServerInformation toToMServerInformation() {
    return ToMServerInformation(
      baseUrl: baseUrl != null ? Uri.parse(baseUrl!) : null,
      serverName: serverName,
    );
  }

  factory ToMServerInformationHiveObj.fromToMServerInformation(
      ToMServerInformation toMServerInformation) {
    return ToMServerInformationHiveObj(
      toMServerInformation.baseUrl?.toString(),
      toMServerInformation.serverName,
    );
  }
}
