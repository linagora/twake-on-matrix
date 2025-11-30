import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';

class SendFilesLoadingWithPlaceholder extends Success {
  final Map<TransactionId, FileInfo> txIdMapfileInfos;

  const SendFilesLoadingWithPlaceholder({required this.txIdMapfileInfos});

  @override
  List<Object?> get props => [txIdMapfileInfos];
}
