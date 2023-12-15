import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class PresentationServerSideSearch extends Equatable {
  final List<Result> searchResults;

  const PresentationServerSideSearch({
    required this.searchResults,
  });

  @override
  List<Object> get props => [searchResults];
}
