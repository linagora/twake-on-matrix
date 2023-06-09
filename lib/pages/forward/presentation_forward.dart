import 'package:equatable/equatable.dart';

enum ForwardTypeEnum {
  recently,
  contacts,
}
class PresentationForward extends Equatable {
  final String id;
  final ForwardTypeEnum type;

  const PresentationForward(this.id, this.type);

  @override
  List<Object?> get props => [id, type];
}