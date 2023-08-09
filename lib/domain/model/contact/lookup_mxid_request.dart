import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_mxid_request.g.dart';

@JsonSerializable()
class LookupMxidRequest with EquatableMixin {
  final List<String> scope;

  final List<String> fields;

  final String? val;

  final int? limit;

  final int? offset;

  LookupMxidRequest({
    required this.scope,
    required this.fields,
    this.val,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [scope, fields, val, limit, offset];

  factory LookupMxidRequest.fromJson(Map<String, dynamic> json) =>
      _$LookupMxidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LookupMxidRequestToJson(this);
}
