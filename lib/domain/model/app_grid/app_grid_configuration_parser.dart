import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:twake_chat/config/app_grid_config/app_config_parser.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';
import 'package:matrix/matrix.dart';

class AppGridConfigurationParser extends AppConfigParser<LinagoraApplications> {
  @override
  Future<LinagoraApplications> parse(String value) async {
    try {
      final jsonObject = jsonDecode(value);
      return LinagoraApplications.fromJson(jsonObject);
    } catch (e) {
      Logs().e('AppDashboardConfigurationParser::parse(): $e');
      rethrow;
    }
  }

  @override
  Future<LinagoraApplications> parseData(ByteData data) {
    throw UnimplementedError();
  }
}
