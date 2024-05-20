import 'package:fluffychat/app_state/failure.dart';

class GetPresentationContactsEmpty extends Failure {
  final String? keyword;

  const GetPresentationContactsEmpty({
    this.keyword,
  });

  @override
  List<Object?> get props => [keyword];
}
