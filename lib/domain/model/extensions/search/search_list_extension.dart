import 'package:fluffychat/domain/model/extensions/search/search_extension.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension SearchListExtenstion on List<SearchModel> {
  List<PresentationSearch> toPresentationSearch() {
    return map((search) => search.toPresentationSearch()).toList();
  }
}