import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:twake_chat/providers/active_user_id_provider.dart';

/// The active user id of a test that switches account. A Matrix `Client` needs
/// a database to log in, and the Drive code only reads the user id.
class FakeActiveUserId extends Notifier<String?> {
  @override
  String? build() => '@alice:example.org';

  void switchTo(String userId) => state = userId;
}

final fakeActiveUserIdProvider = NotifierProvider<FakeActiveUserId, String?>(
  FakeActiveUserId.new,
);

Override followFakeActiveUserId() => activeUserIdProvider.overrideWith(
  (ref) => ref.watch(fakeActiveUserIdProvider),
);
