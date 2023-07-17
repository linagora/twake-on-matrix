import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';

class GetContactAndRecentChatSuccess extends Success {
  final List<SearchModel> search;

  const GetContactAndRecentChatSuccess({required this.search});

  @override
  List<Object?> get props => [search];
}

class GetContactAndRecentChatFailed extends Failure {

  final dynamic exception;

  const GetContactAndRecentChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];

}