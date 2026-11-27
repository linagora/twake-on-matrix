import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/domain/presence/usecases/watch_presence_usecase.provider.dart';

part 'person_presence_provider.g.dart';

/// The presence of [userId] for the active account, read once from the server;
/// loading until the first value arrives.
@riverpod
Stream<PersonPresence?> personPresence(Ref ref, String userId) => ref
    .watch(watchPresenceUseCaseProvider)
    .execute(userId, readFromServer: true);

/// The presence of [userId] as the `/sync` keeps it, without a server read,
/// for the people of a list.
@riverpod
Stream<PersonPresence?> syncedPersonPresence(Ref ref, String userId) => ref
    .watch(watchPresenceUseCaseProvider)
    .execute(userId, readFromServer: false);
