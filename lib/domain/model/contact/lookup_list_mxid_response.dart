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
  final Map<String, Set<String>>? thirdPartyMappings;

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
