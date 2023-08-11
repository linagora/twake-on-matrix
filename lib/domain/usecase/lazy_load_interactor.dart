mixin LazyLoadDataMixin {
  LazyLoadInfos calculateLazyLoadInfo({
    required length,
    required offset,
    required limit,
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
