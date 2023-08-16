import 'package:fluffychat/app_state/lazy_load_success.dart';

class PresentaionSearchableSuccess<T> extends LazyLoadSuccess<T> {
  final String keyword;

  const PresentaionSearchableSuccess({
    required super.data,
    required super.offset,
    required super.isEnd,
    required this.keyword,
  });

  @override
  List<Object?> get props => [data, offset, isEnd, keyword];

  @override
  String toString() =>
      "PresentaionSearchableSuccess data: ${data.length}, offset: $offset, isEnd: $isEnd, keyword: $keyword";
}
