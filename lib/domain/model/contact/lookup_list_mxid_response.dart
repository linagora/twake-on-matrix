import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_list_mxid_response.g.dart';

@JsonSerializable()
class LookupListMxidResponse extends Equatable {
  @JsonKey(name: 'mappings')
  final Map<String, String>? mappings;

  @JsonKey(name: 'inactive_mappings')
  final Map<String, String>? inactiveMappings;

  @JsonKey(name: 'third_party_mappings')
  final Map<String, ThirdPartyMappingsData>? thirdPartyMappings;

  const LookupListMxidResponse({
    this.mappings,
    this.inactiveMappings,
    this.thirdPartyMappings,
  });

  factory LookupListMxidResponse.fromJson(Map<String, dynamic> json) =>
      _$LookupListMxidResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LookupListMxidResponseToJson(this);

  @override
  List<Object?> get props => [
        mappings,
        inactiveMappings,
        thirdPartyMappings,
      ];
}

@JsonSerializable()
class ThirdPartyMappingsData with EquatableMixin {
  @JsonKey(name: 'actives')
  final Set<String>? actives;
  @JsonKey(name: 'inactives')
  final Set<String>? inactives;

  ThirdPartyMappingsData({
    this.actives,
    this.inactives,
  });

  factory ThirdPartyMappingsData.fromJson(Map<String, dynamic> json) =>
      _$ThirdPartyMappingsDataFromJson(json);

  Map<String, dynamic> toJson() => _$ThirdPartyMappingsDataToJson(this);

  @override
  List<Object?> get props => [actives, inactives];
}
