import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class ServerSideSearchCategories with EquatableMixin {
  final String searchTerm;
  final SearchFilter? searchFilter;

  const ServerSideSearchCategories({
    required this.searchTerm,
    this.searchFilter,
  });

  @override
  List<Object?> get props => [searchTerm, searchFilter];

  Categories get searchCategories {
    return Categories(
      roomEvents: RoomEventsCriteria(
        searchTerm: searchTerm,
        groupings: Groupings(
          groupBy: [Group(key: GroupKey.roomId)],
        ),
        orderBy: SearchOrder.recent,
        filter: searchFilter,
      ),
    );
  }
}
