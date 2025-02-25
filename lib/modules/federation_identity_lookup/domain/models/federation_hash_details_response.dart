import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_hash_details_response.g.dart';

@JsonSerializable()
class FederationHashDetailsResponse extends Equatable {
  @JsonKey(name: 'algorithms')
  final Set<String>? algorithms;

  @JsonKey(name: 'lookup_pepper')
  final String? lookupPepper;

  const FederationHashDetailsResponse({
    this.algorithms,
    this.lookupPepper,
  });

  @override
  List<Object?> get props => [algorithms, lookupPepper];

  factory FederationHashDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$FederationHashDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FederationHashDetailsResponseToJson(this);
}
