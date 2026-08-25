import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/presentation/extensions/send_file_extension.dart';

class SendFilesLoadingWithPlaceholder extends Success {
  final Map<TransactionId, FileInfo> txIdMapfileInfos;

  const SendFilesLoadingWithPlaceholder({required this.txIdMapfileInfos});

  @override
  List<Object?> get props => [txIdMapfileInfos];
}
