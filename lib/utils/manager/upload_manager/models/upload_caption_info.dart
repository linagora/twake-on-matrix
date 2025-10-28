import 'package:equatable/equatable.dart';

class UploadCaptionInfo with EquatableMixin {
  final String txid;
  final String caption;

  UploadCaptionInfo({
    required this.caption,
    required this.txid,
  });

  @override
  List<Object?> get props => [caption, txid];
}
