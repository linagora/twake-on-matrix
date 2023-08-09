import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/tom_server_information.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tom_server_information_hive_obj.g.dart';

@JsonSerializable(explicitToJson: true)
class ToMServerInformationHiveObj with EquatableMixin {
  final String? baseUrl;

  final String? serverName;

  ToMServerInformationHiveObj(this.baseUrl, this.serverName);

  factory ToMServerInformationHiveObj.fromJson(Map<String, dynamic> json) =>
      _$ToMServerInformationHiveObjFromJson(json);

  Map<String, dynamic> toJson() => _$ToMServerInformationHiveObjToJson(this);

  @override
  List<Object?> get props => [baseUrl, serverName];

  ToMServerInformation toToMServerInformation() {
    return ToMServerInformation(
      baseUrl: baseUrl != null ? Uri.parse(baseUrl!) : null,
      serverName: serverName,
    );
  }

  factory ToMServerInformationHiveObj.fromToMServerInformation(
    ToMServerInformation toMServerInformation,
  ) {
    return ToMServerInformationHiveObj(
      toMServerInformation.baseUrl?.toString(),
      toMServerInformation.serverName,
    );
  }
}
