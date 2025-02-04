import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_lookup_mxid_response.g.dart';

@JsonSerializable()
class FederationLookupMxidResponse extends Equatable {
  @JsonKey(name: 'mappings')
  final Map<String, String>? mappings;

  @JsonKey(name: 'inactive_mappings')
  final Map<String, String>? inactiveMappings;

  const FederationLookupMxidResponse({
    this.mappings,
    this.inactiveMappings,
  });

  factory FederationLookupMxidResponse.fromJson(Map<String, dynamic> json) =>
      _$FederationLookupMxidResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FederationLookupMxidResponseToJson(this);

  @override
  List<Object?> get props => [mappings, inactiveMappings];
}
