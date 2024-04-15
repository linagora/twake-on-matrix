import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/dialog/downloading_file_dialog_style.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DownloadingFileDialog extends StatelessWidget {
  const DownloadingFileDialog({
    super.key,
    required this.parentContext,
    required this.eventId,
    required this.downloadProgressNotifier,
  });

  final BuildContext parentContext;

  final String eventId;

  final ValueNotifier<double?> downloadProgressNotifier;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: DownloadingFileDialogStyle.dialogWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(
                DownloadingFileDialogStyle.borderRadiusDialog,
              ),
            ),
            padding: DownloadingFileDialogStyle.paddingDialog,
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.of(parentContext)!.downloading,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: DownloadingFileDialogStyle.titleFontSize,
                        ),
                  ),
                  const SizedBox(height: 16.0),
                  ValueListenableBuilder(
                    valueListenable: downloadProgressNotifier,
                    builder: (context, downloadProgress, child) {
                      final downloadPercentage = (downloadProgress ?? 0) * 100;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DownloadingFileDialogStyle.borderRadiusLoading,
                            ),
                            child: LinearProgressIndicator(
                              backgroundColor: DownloadingFileDialogStyle
                                  .backgroundColorLoading,
                              value: downloadProgress,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '${downloadPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: DownloadingFileDialogStyle.fontSize,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            DownloadingFileDialogStyle.borderRadiusDialog,
                          ),
                          onTap: () => onCloseTap(context),
                          child: Padding(
                            padding: DownloadingFileDialogStyle.paddingButton,
                            child: Text(
                              L10n.of(parentContext)!.cancel,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: DownloadingFileDialogStyle.fontSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onCloseTap(BuildContext context) {
    final downloadManager = getIt.get<DownloadManager>();
    downloadManager.cancelDownload(eventId);
    Navigator.of(context, rootNavigator: true).pop();
  }
}
