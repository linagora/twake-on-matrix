import 'dart:async';
import 'dart:collection';

import 'package:fluffychat/utils/task_queue/task.dart';
import 'package:matrix/matrix.dart';

typedef OnTaskCompleted = void Function(String? taskId);

abstract class WorkerQueue {
  final Queue<Task> _queue = Queue<Task>();
  Completer? _completer;

  String get workerName;

  Queue<Task> get queue => _queue;

  Future addTask(Task task, {bool isFirstPriority = false}) {
    if (isFirstPriority) {
      _queue.addFirst(task);
    } else {
      _queue.add(task);
    }
    Logs().i(
      'WorkerQueue<$workerName>::addTask(): QUEUE_LENGTH: ${_queue.length}',
    );
    return _processTask();
  }

  Future _processTask() async {
    try {
      if (_completer != null) {
        return _completer!.future;
      }
      _completer = Completer();
      if (_queue.isNotEmpty) {
        final firstTask = _queue.removeFirst();
        Logs().i('WorkerQueue<$workerName>::_processTask(): ${firstTask.id}');
        firstTask
            .execute()
            .then(_handleTaskExecuteCompleted)
            .catchError(_handleTaskExecuteError)
            .whenComplete(() {
          firstTask.onTaskCompleted?.call();
        });
      } else {
        _completer?.complete();
      }
      return _completer!.future;
    } catch (e) {
      Logs().e('WorkerQueue<$workerName>::_processTask(): $e');
      _completer?.complete(e);
    }
  }

  void _handleTaskExecuteCompleted(dynamic value) {
    Logs().i('WorkerQueue<$workerName>::_handleTaskExecuteCompleted(): $value');
    _completer?.complete(value);
    _releaseCompleter();
    if (_queue.isNotEmpty) {
      _processTask();
    }
  }

  void _handleTaskExecuteError(error) {
    Logs().i('WorkerQueue<$workerName>::_handleTaskExecuteError(): $error');
    _completer?.complete(error);
    _releaseCompleter();
    if (_queue.isNotEmpty) {
      _processTask();
    }
  }

  void _releaseCompleter() {
    _completer = null;
  }

  Future release() async {
    Logs().i('WorkerQueue<$workerName>::release():');
    _queue.clear();
    _releaseCompleter();
  }
}
