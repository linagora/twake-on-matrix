import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tom_server_information.g.dart';

@JsonSerializable()
class ToMServerInformation with EquatableMixin {
  static const String tomServerKey = 't.server';

  @JsonKey(name: 'base_url')
  final Uri? baseUrl;

  @JsonKey(name: 'server_name')
  final String? serverName;

  ToMServerInformation({
    this.baseUrl,
    this.serverName,
  });

  factory ToMServerInformation.fromJson(Map<String, dynamic> json) =>
      _$ToMServerInformationFromJson(json);

  Map<String, dynamic> toJson() => _$ToMServerInformationToJson(this);

  @override
  List<Object?> get props => [baseUrl, serverName];
}
