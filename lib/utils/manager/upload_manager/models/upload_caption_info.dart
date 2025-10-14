import 'package:equatable/equatable.dart';

class UploadCaptionInfo with EquatableMixin {
  final String caption;

  UploadCaptionInfo({
    required this.caption,
  });

  @override
  List<Object?> get props => [caption];
}
