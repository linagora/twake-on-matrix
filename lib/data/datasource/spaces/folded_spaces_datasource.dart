abstract class FoldedSpacesDatasource {
  Future<Set<String>> read(String userId);

  Future<void> write(String userId, Set<String> spaceIds);
}
