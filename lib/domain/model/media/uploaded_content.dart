import 'package:equatable/equatable.dart';

class UploadedContent with EquatableMixin {
  final String? contentUri;

  UploadedContent(this.contentUri);

  @override
  List<Object?> get props => [contentUri];
}
