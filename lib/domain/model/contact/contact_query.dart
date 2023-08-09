import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/query.dart';

class ContactQuery extends Query with EquatableMixin {
  ContactQuery({
    required super.keyword,
  });

  @override
  List<Object?> get props => [keyword];
}
