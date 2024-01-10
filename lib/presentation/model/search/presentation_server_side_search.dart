import 'package:fluffychat/presentation/model/search/presentation_server_side_state.dart';
import 'package:matrix/matrix.dart';

class PresentationServerSideSearch extends PresentationServerSideUIState {
  final List<Result> searchResults;

  PresentationServerSideSearch({
    required this.searchResults,
  });

  @override
  List<Object> get props => [searchResults];
}
