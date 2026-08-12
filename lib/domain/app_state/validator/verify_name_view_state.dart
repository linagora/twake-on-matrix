import 'package:twake_chat/presentation/state/failure.dart';
import 'package:twake_chat/presentation/state/success.dart';

class VerifyNameSuccessViewState extends UIState {}

class VerifyNameFailure extends FeatureFailure {
  const VerifyNameFailure(dynamic exception) : super(exception: exception);
}
