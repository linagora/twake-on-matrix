import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_resolved.dart';

extension ThreadResolvedExtension on Room {
  bool isThreadResolved(String rootId) =>
      getState(threadResolvedStateType, rootId)?.content['resolved'] == true;

  /// `canChangeStateEvent` falls back on `state_default`, as the server does
  /// for a state event.
  bool get canResolveThreads => canChangeStateEvent(threadResolvedStateType);
}
