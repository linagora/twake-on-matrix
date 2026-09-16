import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/feed/feed_repository.provider.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';

part 'new_feed_providers.g.dart';

@riverpod
CreateNewFeedInteractor createNewFeedInteractor(Ref ref, Client client) =>
    CreateNewFeedInteractor(ref.watch(feedRepositoryProvider(client)));
