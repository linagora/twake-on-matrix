import 'package:fluffychat/utils/manager/download_manager/downloading_worker_queue.dart';
import 'package:fluffychat/utils/task_queue/task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  // Helper function to generate tasks
  Task generateTask(
    String taskId,
    Future Function() runnable, {
    void Function()? onTaskCompleted,
  }) {
    return Task(
      id: taskId,
      runnable: runnable,
      onTaskCompleted: onTaskCompleted,
    );
  }

  // Testing group for worker queue
  group("worker queue test", () {
    // Test case for adding tasks without cancelation or error
    test("""
      WHEN add 4 tasks without any cancel or error in worker queue,
      SHOULD completed tasks should be order and in time
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];
      final tasks = List.generate(4, (index) {
        return generateTask(
          '${index + 1}',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(index + 1);
            return index + 1;
          }),
          onTaskCompleted: () {
            Logs().i('task${index + 1} completed');
            completedTasks.add(index + 1);
          },
        );
      });

      final workerQueue = DownloadWorkerQueue();
      tasks.forEach(workerQueue.addTask);

      await Future.delayed(const Duration(seconds: 1));
      expect(workerQueue.queue.length, 3);
      await Future.delayed(const Duration(seconds: 1));
      expect(workerQueue.queue.length, 2);
      await Future.delayed(const Duration(seconds: 7));
      // Verify that all tasks completed in the expected order
      expect(completedTasks, [1, 2, 3, 4]);
      expect(alreadyRunTasks, [1, 2, 3, 4]);
    });

    test("""
      WHEN add 4 tasks consecutively,
      THEN there is an error task while the other task is running
      SHOULD completed tasks should be order
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];
      final errorTasks = <String>[];

      final tasks = [
        generateTask(
          '1',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(1);
            return 1;
          }),
          onTaskCompleted: () {
            Logs().i('task1 completed');
            completedTasks.add(1);
          },
        ),
        generateTask(
          '2',
          () async {
            await Future.delayed(const Duration(seconds: 1));
            errorTasks.add('task2 error');
            throw Exception('task2 error');
          },
          onTaskCompleted: () {
            Logs().i('task2 completed');
            completedTasks.add(2);
          },
        ),
        generateTask(
          '3',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(3);
            return 3;
          }),
          onTaskCompleted: () {
            Logs().i('task3 completed');
            completedTasks.add(3);
          },
        ),
        generateTask(
          '4',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(4);
            return 4;
          }),
          onTaskCompleted: () {
            Logs().i('task4 completed');
            completedTasks.add(4);
          },
        ),
      ];

      final workerQueue = DownloadWorkerQueue();
      try {
        for (final task in tasks) {
          workerQueue.addTask(task);
        }
      } catch (e) {
        Logs().e('workerQueue.addTask(): $e');
      }

      await Future.delayed(const Duration(seconds: 10));
      // Verify that completedTasks includes tasks 1, 3, and 4 but not the errored task 2
      expect(completedTasks, containsAllInOrder([1, 3, 4]));
      expect(alreadyRunTasks, containsAllInOrder([1, 3, 4]));
      expect(
        errorTasks,
        ['task2 error'],
      ); // Verify that task 2's error is recorded
    });

    test("""
      WHEN a task is processing in queue with 4 tasks
      THEN add a new task to the queue
      SHOULD the new task should be added to the end of the queue
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];
      final tasks = List.generate(4, (index) {
        return generateTask(
          '${index + 1}',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(index + 1);
            return index + 1;
          }),
          onTaskCompleted: () {
            Logs().i('task${index + 1} completed');
            completedTasks.add(index + 1);
          },
        );
      });

      final workerQueue = DownloadWorkerQueue();
      tasks.forEach(workerQueue.addTask);

      await Future.delayed(const Duration(seconds: 1));
      expect(workerQueue.queue.length, 3);

      workerQueue.addTask(
        Task(
          id: '5',
          runnable: () async =>
              await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(5);
            return 5;
          }),
          onTaskCompleted: () {
            Logs().i('task5 completed');
            completedTasks.add(5);
          },
        ),
      );

      expect(workerQueue.queue.length, 4);
      await Future.delayed(const Duration(seconds: 10));
      // Verify that all tasks completed in the expected order
      expect(completedTasks, containsAllInOrder([1, 2, 3, 4]));
      expect(alreadyRunTasks, containsAllInOrder([1, 2, 3, 4]));
    });

    test("""
      WHEN add 4 tasks with the same task id to the worker queue,
      SHOULD the queue executes task in order and consider the duplicate task id as normal task
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];
      final tasks = List.generate(4, (index) {
        return generateTask(
          '1',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(index + 1);
            return index + 1;
          }),
          onTaskCompleted: () {
            Logs().i('task${index + 1} completed');
            completedTasks.add(index + 1);
          },
        );
      });

      final workerQueue = DownloadWorkerQueue();
      tasks.forEach(workerQueue.addTask);

      await Future.delayed(const Duration(seconds: 1));
      expect(workerQueue.queue.length, 3);
      expect(workerQueue.queue.first.id, '1');

      await Future.delayed(const Duration(seconds: 1));
      expect(workerQueue.queue.length, 2);
      await Future.delayed(const Duration(seconds: 7));
      // Verify that all tasks completed in the expected order
      expect(completedTasks, containsAllInOrder([1, 2, 3, 4]));
      expect(alreadyRunTasks, containsAllInOrder([1, 2, 3, 4]));
    });

    test("""
      WHEN add 4 tasks with the same task id to the worker queue,
      THEN in task complete, there is async task
      SHOULD async task do not block any task in the queue
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];
      final tasks = List.generate(4, (index) {
        return generateTask(
          '1',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(index + 1);
            return index + 1;
          }),
          onTaskCompleted: () async {
            Logs().i('task${index + 1} completed');
            await Future.delayed(const Duration(seconds: 1));
            completedTasks.add(index + 1);
          },
        );
      });

      final workerQueue = DownloadWorkerQueue();
      tasks.forEach(workerQueue.addTask);

      await Future.delayed(const Duration(seconds: 9));
      // Verify that all tasks completed in the expected order
      expect(alreadyRunTasks, containsAllInOrder([1, 2, 3, 4]));
      await Future.delayed(const Duration(seconds: 4));
      expect(completedTasks, containsAllInOrder([1, 2, 3, 4]));
    });

    test("""
      WHEN add 4 tasks at once to the queue using Future.wait
      SHOULD the tasks are executed in order and the queue is empty after all tasks are completed
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];

      final tasks = List.generate(4, (index) {
        return generateTask(
          '1',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(index + 1);
            return index + 1;
          }),
          onTaskCompleted: () async {
            Logs().i('task${index + 1} completed');
            completedTasks.add(index + 1);
          },
        );
      });

      final workerQueue = DownloadWorkerQueue();
      Future.wait(tasks.map((task) => workerQueue.addTask(task)));
      await Future.delayed(const Duration(seconds: 1));
      expect(workerQueue.queue.length, 3);
      expect(workerQueue.queue.first.id, '1');

      await Future.delayed(const Duration(seconds: 9));
      // Verify that all tasks completed in the expected order
      expect(alreadyRunTasks, containsAllInOrder([1, 2, 3, 4]));
      expect(completedTasks, containsAllInOrder([1, 2, 3, 4]));
    });

    test("""
      WHEN add 4 tasks to the worker queue
      THEN task 1 is processing
      THEN remove the last task from the queue
      SHOULD the queue executes task except the removed task
    """, () async {
      final completedTasks = <int>[];
      final alreadyRunTasks = <int>[];

      final tasks = List.generate(4, (index) {
        return generateTask(
          '1',
          () async => await Future.delayed(const Duration(seconds: 2), () {
            alreadyRunTasks.add(index + 1);
            return index + 1;
          }),
          onTaskCompleted: () async {
            Logs().i('task${index + 1} completed');
            completedTasks.add(index + 1);
          },
        );
      });

      final workerQueue = DownloadWorkerQueue();
      Future.wait(tasks.map((task) => workerQueue.addTask(task)));
      await Future.delayed(const Duration(seconds: 1));

      workerQueue.queue.removeLast();
      // Verify that the worker queue has 2 remaining tasks and the first task is being processed
      expect(workerQueue.queue.length, 2);
      expect(workerQueue.queue.first.id, '1');

      await Future.delayed(const Duration(seconds: 7));
      // Verify that all tasks completed in the expected order
      expect(alreadyRunTasks, containsAllInOrder([1, 2, 3]));
      expect(completedTasks, containsAllInOrder([1, 2, 3]));
    });
  });
}
