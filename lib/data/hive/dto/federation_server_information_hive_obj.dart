import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/model/federation_server/federation_server_information.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_server_information_hive_obj.g.dart';

@JsonSerializable(explicitToJson: true)
class FederationServerInformationHiveObj with EquatableMixin {
  final List<String>? baseUrls;

  FederationServerInformationHiveObj({required this.baseUrls});

  factory FederationServerInformationHiveObj.fromJson(
    Map<String, dynamic> json,
  ) => _$FederationServerInformationHiveObjFromJson(json);

  Map<String, dynamic> toJson() =>
      _$FederationServerInformationHiveObjToJson(this);

  FederationServerInformation toFederationServerInformation() {
    return FederationServerInformation(
      baseUrls: baseUrls?.map((e) => Uri.parse(e)).toList(),
    );
  }

  factory FederationServerInformationHiveObj.fromFederationServerInformation(
    FederationServerInformation fedServerInformation,
  ) {
    return FederationServerInformationHiveObj(
      baseUrls: fedServerInformation.baseUrls
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => [baseUrls];
}
