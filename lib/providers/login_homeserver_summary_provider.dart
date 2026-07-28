import 'package:fluffychat/domain/model/homeserver_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'login_homeserver_summary_provider.g.dart';

@Riverpod(keepAlive: true)
class LoginHomeserverSummary extends _$LoginHomeserverSummary {
  @override
  HomeserverSummary? build() => null;

  void set(HomeserverSummary? summary) => state = summary;
}
