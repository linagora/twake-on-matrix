import 'package:fluffychat/app_state/success.dart';

class LazyLoadSuccess<T> extends Success {
  final List<T> data;
  final int offset;
  final bool isEnd;

  const LazyLoadSuccess({
    required this.data,
    required this.offset,
    required this.isEnd,
  });

  @override
  List<Object?> get props => [data, offset, isEnd];

  LazyLoadSuccess<T> operator +(LazyLoadSuccess<T> other) {
    return LazyLoadSuccess(
      data: data + other.data,
      offset: other.offset,
      isEnd: other.isEnd,
    );
  }
}
