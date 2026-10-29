import 'package:twake_chat/domain/reactions/exceptions/recent_reactions_exception.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';

class GetRecentReactionsUseCase {
  const GetRecentReactionsUseCase(this._repository);

  final ReactionsRepository _repository;

  Future<List<String>> execute() async {
    try {
      return await _repository.getRecentReactions();
    } catch (e, s) {
      Error.throwWithStackTrace(GetRecentReactionsException(e), s);
    }
  }
}
