import 'package:fluffychat/utils/task_queue/worker_queue.dart';

class UploadWorkerQueue extends WorkerQueue {
  @override
  String get workerName => 'upload_worker_queue';
}
