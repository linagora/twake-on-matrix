import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'server_search_response.g.dart';

@JsonSerializable()
class ServerSearchResponse with EquatableMixin {
  @JsonKey(name: 'search_categories')
  final ResultCategories searchCategories;

  ServerSearchResponse({
    required this.searchCategories,
  });

  @override
  List<Object?> get props => [searchCategories];

  factory ServerSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$ServerSearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ServerSearchResponseToJson(this);
}
