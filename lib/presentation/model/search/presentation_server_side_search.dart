import 'package:fluffychat/presentation/model/search/presentation_server_side.dart';
import 'package:matrix/matrix.dart';

class PresentationServerSideSearch extends PresentationServerSide {
  final List<Result> searchResults;

  PresentationServerSideSearch({
    required this.searchResults,
  });

  @override
  List<Object> get props => [searchResults];
}
