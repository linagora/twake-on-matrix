import 'package:equatable/equatable.dart';

class CancelRequestException with EquatableMixin {
  final String? reason;

  CancelRequestException({this.reason = ""});

  @override
  List<Object?> get props => [reason];
}
