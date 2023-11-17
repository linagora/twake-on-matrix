import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_list_mxid_request.g.dart';

@JsonSerializable()
class LookupListMxidRequest extends Equatable {
  final Set<String>? addresses;
  final String? algorithm;
  final String? pepper;

  const LookupListMxidRequest({
    this.addresses,
    this.algorithm,
    this.pepper,
  });

  factory LookupListMxidRequest.fromJson(Map<String, dynamic> json) =>
      _$LookupListMxidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LookupListMxidRequestToJson(this);

  @override
  List<Object?> get props => [addresses, algorithm, pepper];
}
