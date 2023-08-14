import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';

class SearchInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class SearchRecentChatSuccess extends Success {
  final Iterable<RecentChatSearchModel> data;
  final String keyword;

  const SearchRecentChatSuccess({
    required this.data,
    required this.keyword,
  });

  @override
  List<Object?> get props => [data, keyword];
}

class SearchRecentChatFailed extends Failure {
  final dynamic exception;

  const SearchRecentChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
