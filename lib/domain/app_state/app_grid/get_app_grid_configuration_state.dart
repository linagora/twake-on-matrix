import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/app_grid/linagora_applications.dart';

class LoadingAppGridConfiguration extends Success {
  @override
  List<Object?> get props => [];
}

class GetAppGridConfigurationSuccess extends Success {
  final LinagoraApplications linagoraApplications;

  const GetAppGridConfigurationSuccess(this.linagoraApplications);

  @override
  List<Object> get props => [linagoraApplications];
}

class GetAppGridConfigurationFailure extends Failure {
  final dynamic exception;

  const GetAppGridConfigurationFailure({
    required this.exception,
  });

  @override
  List<Object?> get props => [exception];
}
