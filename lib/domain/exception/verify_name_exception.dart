import 'package:equatable/equatable.dart';

abstract class VerifyNameException extends Equatable implements Exception {
  static const nameWithOnlySpace = 'The name cannot contain only spaces';
  static const emptyName = 'The name cannot be empty';

  final String? message;
  const VerifyNameException(this.message);

  @override
  List<Object?> get props => [message];
}

class NameWithSpaceOnlyException extends VerifyNameException {
  const NameWithSpaceOnlyException()
      : super(VerifyNameException.nameWithOnlySpace);
}

class EmptyNameException extends VerifyNameException {
  const EmptyNameException() : super(VerifyNameException.emptyName);
}
