import 'package:fluffychat/app_state/lazy_load_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

class GetContactAndRecentChatPresentation
    extends LazyLoadSuccess<PresentationSearch> {
  final String keyword;

  const GetContactAndRecentChatPresentation({
    required super.data,
    required super.offset,
    required super.isEnd,
    required this.keyword,
  });

  @override
  List<Object?> get props => [data, offset, isEnd, keyword];
}
