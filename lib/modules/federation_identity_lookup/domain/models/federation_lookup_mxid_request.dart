import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_lookup_mxid_request.g.dart';

@JsonSerializable()
class FederationLookupMxidRequest extends Equatable {
  @JsonKey(name: 'addresses')
  final Set<String>? addresses;
  @JsonKey(name: 'algorithm')
  final String? algorithm;
  @JsonKey(name: 'pepper')
  final String? pepper;

  const FederationLookupMxidRequest({
    this.addresses,
    this.algorithm,
    this.pepper,
  });

  factory FederationLookupMxidRequest.fromJson(Map<String, dynamic> json) =>
      _$FederationLookupMxidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FederationLookupMxidRequestToJson(this);

  @override
  List<Object?> get props => [addresses, algorithm, pepper];
}
