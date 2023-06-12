import 'package:equatable/equatable.dart';

enum ForwardTypeEnum {
  recently,
  contacts,
}

class ForwardToSelection extends Equatable {
  final String id;
  final ForwardTypeEnum type;

  const ForwardToSelection(this.id, this.type);

  @override
  List<Object?> get props => [id, type];
}