mixin LazyLoadDataMixin {
  LazyLoadInfos calculateLazyLoadInfo({
    required int length,
    required int offset,
    required int limit,
  }) {
    final isEnd = length < limit;
    return LazyLoadInfos(isEnd: isEnd, offset: isEnd ? offset : offset + limit);
  }
}

class LazyLoadInfos {
  final bool isEnd;
  final int offset;

  LazyLoadInfos({required this.isEnd, required this.offset});
}
