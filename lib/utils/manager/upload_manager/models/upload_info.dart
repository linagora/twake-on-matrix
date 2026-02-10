import 'package:equatable/equatable.dart';

abstract class UploadInfo with EquatableMixin {
  final String txid;

  UploadInfo({required this.txid});

  @override
  List<Object?> get props => [txid];
}
