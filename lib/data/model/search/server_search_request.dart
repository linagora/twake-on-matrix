import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'server_search_request.g.dart';

@JsonSerializable()
class ServerSearchRequest with EquatableMixin {
  @JsonKey(name: 'search_categories')
  final Categories searchCategories;

  ServerSearchRequest({required this.searchCategories});

  @override
  List<Object?> get props => [searchCategories];

  factory ServerSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$ServerSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ServerSearchRequestToJson(this);
}
