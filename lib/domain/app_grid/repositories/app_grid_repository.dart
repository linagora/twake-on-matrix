import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

abstract interface class AppGridRepository {
  Future<LinagoraApplications> getConfiguration(String path);
}
