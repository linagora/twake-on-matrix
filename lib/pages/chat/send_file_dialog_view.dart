import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/chat/send_file_dialog_style.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

class SendFileDialogView extends StatelessWidget {
  final SendFileDialogController controller;

  const SendFileDialogView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius:
            BorderRadius.circular(SendFileDialogStyle.dialogBorderRadius),
        child: Container(
          width: SendFileDialogStyle.dialogWidth,
          padding: EdgeInsets.all(SendFileDialogStyle.dialogBorderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: SendFileDialogStyle.headerPadding,
                    child: Text(
                      L10n.of(context)!.sendImages(1),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              InkWell(
                onTap: () {
                  Navigator.of(context, rootNavigator: PlatformInfos.isWeb)
                      .push(
                    HeroPageRoute(
                      builder: (context) {
                        return InteractiveViewerGallery(
                          itemBuilder: ImageViewer(
                            imageData: controller.widget.files.first.bytes,
                          ),
                        );
                      },
                    ),
                  );
                },
                child: SizedBox(
                  width: SendFileDialogStyle.imageSize,
                  height: SendFileDialogStyle.imageSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      SendFileDialogStyle.imageBorderRadius,
                    ),
                    child: Image.memory(
                      controller.widget.files.first.bytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              InputBar(
                maxLines: 5,
                minLines: 1,
                focusSuggestionController: controller.focusSuggestionController,
                room: controller.widget.room,
                controller: controller.textEditingController,
                decoration:
                    SendFileDialogStyle.bottomBarInputDecoration(context),
                keyboardType: TextInputType.multiline,
                enablePasteImage: false,
              ),
              SendFileDialogStyle.spaceBwInputBarAndButton,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ButtonStyle(
                      shape: MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SendFileDialogStyle.buttonBorderRadius,
                          ),
                        ),
                      ),
                      padding: MaterialStatePropertyAll(
                        SendFileDialogStyle.buttonPadding,
                      ),
                    ),
                    child: Text(
                      L10n.of(context)!.cancel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  TextButton(
                    onPressed: controller.send,
                    autofocus: true,
                    style: ButtonStyle(
                      shape: MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SendFileDialogStyle.buttonBorderRadius,
                          ),
                        ),
                      ),
                      backgroundColor: MaterialStatePropertyAll(
                        Theme.of(context).colorScheme.primary,
                      ),
                      padding: MaterialStatePropertyAll(
                        SendFileDialogStyle.buttonPadding,
                      ),
                    ),
                    child: Text(
                      L10n.of(context)!.send,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
