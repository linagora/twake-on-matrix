import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class ReportContentLoading extends Success {
  const ReportContentLoading();

  @override
  List<Object?> get props => [];
}

class ReportContentSuccess extends Success {
  const ReportContentSuccess();

  @override
  List<Object?> get props => [];
}

class ReportContentFailure extends Failure {
  final dynamic exception;

  const ReportContentFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}
