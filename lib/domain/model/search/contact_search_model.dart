import 'package:fluffychat/domain/model/search/search_model.dart';

class ContactSearchModel extends SearchModel {
  final String? matrixId;

  final String? email;

  const ContactSearchModel(
    this.matrixId,
    this.email, {
    super.displayName,
  });

  @override
  String get id => matrixId ?? email ?? '';

  @override
  List<Object?> get props => [matrixId, email, displayName];
}
