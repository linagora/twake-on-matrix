import 'package:twake_chat/app_state/failure.dart';

class GetPresentationContactsFailure extends Failure {
  final String keyword;

  const GetPresentationContactsFailure({required this.keyword});

  @override
  List<Object> get props => [keyword];
}
