
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_mxid_request.g.dart';

@JsonSerializable()
class LookupMxidRequest with EquatableMixin {

  final List<String> scopes;

  final List<String> fields;

  final String val;

  LookupMxidRequest({
    required this.scopes,
    required this.fields,
    required this.val,
  });
    
  @override
  List<Object?> get props => [scopes, fields, val];

  factory LookupMxidRequest.fromJson(Map<String, dynamic> json) 
    => _$LookupMxidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LookupMxidRequestToJson(this);
}