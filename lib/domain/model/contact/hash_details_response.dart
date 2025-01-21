import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hash_details_response.g.dart';

@JsonSerializable()
class HashDetailsResponse extends Equatable {
  @JsonKey(name: 'algorithms')
  final Set<String>? algorithms;

  @JsonKey(name: 'lookup_pepper')
  final String? lookupPepper;

  @JsonKey(name: 'alt_lookup_peppers')
  final Set<String>? altLookupPeppers;

  const HashDetailsResponse({
    this.algorithms,
    this.lookupPepper,
    this.altLookupPeppers,
  });

  @override
  List<Object?> get props => [algorithms, lookupPepper, altLookupPeppers];

  factory HashDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$HashDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HashDetailsResponseToJson(this);
}
