import 'package:twake_chat/utils/task_queue/worker_queue.dart';

class UploadWorkerQueue extends WorkerQueue {
  @override
  String get workerName => 'upload_worker_queue';
}
