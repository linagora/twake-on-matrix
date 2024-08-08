import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

class MockSyncUpdate extends Mock implements SyncUpdate {
  @override
  final String nextBatch;

  MockSyncUpdate({required this.nextBatch});

  @override
  String toString() => 'MockSyncUpdate(nextBatch: $nextBatch)';
}
