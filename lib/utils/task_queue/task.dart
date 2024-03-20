import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/utils/task_queue/task_state.dart';

class Task with EquatableMixin {
  final String? id;
  final Future Function() runnable;
  final void Function()? onTaskCompleted;

  Task({
    this.id,
    required this.runnable,
    this.onTaskCompleted,
  });

  Future execute() async {
    final resultCompleter = Completer();
    try {
      final result = await runnable.call();
      resultCompleter.complete(TaskSuccess(result: result));
    } catch (exception) {
      resultCompleter.completeError(TaskFailure(exception: exception));
    }
    return resultCompleter.future;
  }

  @override
  List<Object?> get props => [id, runnable];
}
