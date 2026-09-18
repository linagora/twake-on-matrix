import 'package:twake_chat/domain/repository/feed/feed_repository.dart';

class CreateNewFeedInteractor {
  const CreateNewFeedInteractor(this._feedRepository);

  final FeedRepository _feedRepository;

  Future<String> execute({String? feedName, String? avatarUrl}) =>
      _feedRepository.createFeed(name: feedName, avatarUrl: avatarUrl);
}
