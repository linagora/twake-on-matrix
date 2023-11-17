import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hash_details_response.g.dart';

@JsonSerializable()
class HashDetailsResponse extends Equatable {
  @JsonKey(name: 'algorithms')
  final Set<String>? algorithms;

  @JsonKey(name: 'lookup_pepper')
  final String? lookupPepper;

  const HashDetailsResponse({
    this.algorithms,
    this.lookupPepper,
  });

  @override
  List<Object?> get props => [algorithms, lookupPepper];

  factory HashDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$HashDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HashDetailsResponseToJson(this);
}
