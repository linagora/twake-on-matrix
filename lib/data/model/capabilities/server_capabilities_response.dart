import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'server_capabilities_response.g.dart';

@JsonSerializable()
class ServerCapabilitiesResponse extends Equatable {
  final Capabilities capabilities;

  const ServerCapabilitiesResponse({required this.capabilities});

  factory ServerCapabilitiesResponse.fromJson(Map<String, dynamic> json) =>
      _$ServerCapabilitiesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ServerCapabilitiesResponseToJson(this);

  @override
  List<Object?> get props => [capabilities];
}
